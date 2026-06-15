import os 
import sys
import time
import argparse
import yaml
import requests

RETRYABLE_STATUS_CODES = {502, 503, 429}
MAX_RETRIES = 3
INITIAL_BACKOFF_SECONDS = 2
DELAY_BETWEEN_DISPATCHES = 0.5

def log(logName, logMessage="", level='info'):
    print(f'[{level.upper()}]: logName={logName} {f"logMsg=[{logMessage}]" if logMessage != "" else ""}')

def getAllMicroserviceFiles(directory):
    microserviceFiles = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('microservice.yaml'):
                file = os.path.join(root, file)
                microserviceFiles.append(file)
    return microserviceFiles

def getChangedMicroserviceFiles(baseRefDir, headRefDir):
    modifiedFiles = []
    for microserviceFile in getAllMicroserviceFiles(headRefDir):
        headRefMicroservice = yaml.safe_load(open(microserviceFile, 'r'))

        # If the service is onboarded for the first time
        try:
            baseRefMicroservice = yaml.safe_load(open(microserviceFile.replace(headRefDir, baseRefDir, 1), 'r'))
        except FileNotFoundError:
            log('newServiceAdded', f'New service added in headRef={headRefDir} file={microserviceFile}', 'info')
            modifiedFiles.append(microserviceFile)
            continue

        if headRefMicroservice != baseRefMicroservice:
            modifiedFiles.append(microserviceFile)
    return modifiedFiles

def fetchImageTags(file):
    imageTags = []
    try:
        yamlFile = yaml.safe_load(open(file, 'r'))
        
        # if deployments object is present
        try:
            if 'deployments' in yamlFile['microservice']:
                for deployment in yamlFile['microservice']['deployments']:
                    imageTags.append(deployment['deployment']['image']['tag'])
        except KeyError as e:
            log('KeyErrorWhileFetchingTagsFromDeployments', f'file={file}', 'error')
        
        # if deloyment object is present 
        try:
            if 'deployment' in yamlFile['microservice']:
                imageTags.append(yamlFile['microservice']['deployment']['image']['tag'])
        except KeyError:
            log('KeyErrorWhileFetchingTagsFromDeployment', f'file={file}', 'error')

        # if deploymentFree object is present
        try:
            if 'deploymentFree' in yamlFile['microservice']:
                imageTags.append(yamlFile['microservice']['deploymentFree']['image']['tag'])
        except KeyError:
            log('KeyErrorWhileFetchingTagsFromDeploymentFree', f'file={file}', 'error')

        imageName = yamlFile['microservice']['common']['image']['name']
        return imageTags, imageName
    except FileNotFoundError as e:
        log('fetchImageTags', f'File not found file={file}', 'error')
        return imageTags, None
    except Exception as e:
        log('fetchImageTags', f'Error while fetching image tags from file={file} error={e}', 'error')
        return imageTags, None

def getUpdatedTags(headRefDir, baseRefDir, file):
    headImageTags, imageName = fetchImageTags(file)
    baseImageTags, _ = fetchImageTags(file.replace(headRefDir, baseRefDir, 1))

    log('baseImageTags', f'tags={baseImageTags}')
    log('headImageTags', f'tags={headImageTags}')

    newtags = set()
    oldtags = set()
    # Compare the image tags
    for tag in headImageTags:
        if tag not in baseImageTags:
            newtags.add(tag)
        else:
            oldtags.add(tag)
    return list(newtags), list(oldtags), imageName

def triggerWorkflow(imageName, imageTag, ecrRegion, mergeSha):
    owner = "celigo"
    repo = "cd-prod"
    workflow = "propagate-ecr-images.yaml"
    ref = 'main'

    GIT_PAT = os.environ['GIT_PAT']

    url = f'https://api.github.com/repos/{owner}/{repo}/actions/workflows/{workflow}/dispatches'

    headers = {
        'Authorization': f'Bearer {GIT_PAT}',
        'Content-Type': 'application/json'
    }
    data = {
        'ref': f'{ref}',
        'inputs': {
            'IMAGE_TAG': f'{imageTag}',
            'ECR_REPOSITORY': f'{imageName}',
            'ECR_REGION': f'{ecrRegion}',
            'MERGE_SHA': f'{mergeSha}'
        }
    }

    for attempt in range(1, MAX_RETRIES + 1):
        response = requests.post(url, headers=headers, json=data)
        rc = response.status_code
        log('triggerWorkflow', f'region={ecrRegion} repo={imageName} tag={imageTag} rc={rc} attempt={attempt}/{MAX_RETRIES}')

        if rc == 204:
            return True

        if rc in RETRYABLE_STATUS_CODES and attempt < MAX_RETRIES:
            backoff = INITIAL_BACKOFF_SECONDS * (2 ** (attempt - 1))
            log('triggerWorkflowRetry', f'Retrying in {backoff}s due to rc={rc}', 'warn')
            time.sleep(backoff)
            continue

        log('triggerWorkflowFailed', f'region={ecrRegion} repo={imageName} tag={imageTag} rc={rc} responseBody={response.text}', 'error')
        return False

    return False

def main(args):
    log('paths', f'base-ref={args.base_ref} head-ref={args.head_ref}')
    baseRefDir = args.base_ref
    headRefDir = args.head_ref

    modifiedFiles = getChangedMicroserviceFiles(baseRefDir, headRefDir)
    log('modifiedFiles', f'modifiedFiles={modifiedFiles}')

    ecrRegions = args.ecr_regions.split(',')
    mergeSha = args.merge_sha[:7]

    failures = []
    dispatchCount = 0

    for file in modifiedFiles:
        newtags, oldtags, imageName = getUpdatedTags(headRefDir, baseRefDir, file)
        log('imageTags', f'file={file} newtags={newtags} oldtags={oldtags}')

        for ecrRegion in ecrRegions:
            for tag in newtags:
                if dispatchCount > 0:
                    time.sleep(DELAY_BETWEEN_DISPATCHES)
                success = triggerWorkflow(imageName, tag, ecrRegion, mergeSha)
                dispatchCount += 1
                if not success:
                    failures.append(f'{imageName}:{tag} ({ecrRegion})')

    log('dispatchSummary', f'total={dispatchCount} succeeded={dispatchCount - len(failures)} failed={len(failures)}')
    if failures:
        log('failedDispatches', f'failures={failures}', 'error')
        sys.exit(1)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='This program compares the image tags from the pr')
    parser.add_argument(
        '--base-ref', 
        required=True,
        type=str,
        help='Directory containing the base reference for the comparison')
    parser.add_argument(
        '--head-ref', 
        required=True,
        type=str,
        help='Directory containing the head reference for the comparison')
    parser.add_argument(
        '--ecr-regions',
        required=True,
        type=str,
        help='Comma separated list of ecr regions'
    )
    parser.add_argument(
        '--merge-sha',
        required=True,
        type=str,
        help='sha id of the merge commit'
    )
    
    args = parser.parse_args()
    main(args)