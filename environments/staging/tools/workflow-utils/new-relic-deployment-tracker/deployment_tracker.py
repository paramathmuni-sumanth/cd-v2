import os 
import argparse
import yaml
import requests

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

        newRelicAppName = yamlFile['microservice']['env']['NEW_RELIC_APP_NAME']
        return imageTags, newRelicAppName
    except FileNotFoundError as e:
        return imageTags
    except Exception as e:
        log('fetchImageTags', f'Error while fetching image tags from file={file} error={e}', 'error')
        return imageTags, None

def getUpdatedTags(headRefDir, baseRefDir, file):
    headImageTags, newRelicAppName = fetchImageTags(file)
    baseImageTags, newRelicAppName = fetchImageTags(file.replace(headRefDir, baseRefDir, 1))

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
    return list(newtags), list(oldtags), newRelicAppName

def getApplicationGuid(applicationName):
    url = "https://api.newrelic.com/graphql"

    API_KEY = os.environ['NEW_RELIC_API_KEY']

    headers = {
        'API-Key': API_KEY,
        'Content-Type': 'application/json'
    }

    # The GraphQL query
    query = f"""
    {{
        actor {{
        entitySearch(query: "domain = 'APM' AND type = 'APPLICATION' AND name = '{applicationName}'") {{
            results {{
                entities {{
                    guid 
                    name 
                    }}
                }}
            }}
        }}
    }}
    """

    data = {
    "query": query
    }

    response = requests.post(url, headers=headers, json=data)
    data = response.json()
    try:
        entityGuid = data['data']['actor']['entitySearch']['results']['entities'][0]['guid']
        return entityGuid
    except:
        log('getApplicationGuid', f'Application not found in New Relic for name={applicationName}', 'error')
        return None


def pushToNewRelic(newRelicAppName, imageTag, deploymentType, gitSha):
    entityGuid = getApplicationGuid(newRelicAppName)

    if entityGuid == None:
        return

    url = "https://api.newrelic.com/graphql"

    API_KEY = os.environ['NEW_RELIC_API_KEY']

    mutation = f"""
    mutation {{
    changeTrackingCreateDeployment(
        deployment: {{ version: "{imageTag}", entityGuid: "{entityGuid}", deploymentType: {deploymentType}, commit: "{gitSha}" }}) {{
            deploymentId
        }}
    }}
    """

    data = {
    "query": mutation
    }

    # print(data)
    headers = {
        'API-Key': API_KEY,
        'Content-Type': 'application/json'
    }

    response = requests.post(url, headers=headers, json=data)
    log('pushToNewRelic', f'response={response.json()}')

def main(args):
    log('paths', f'base-ref={args.base_ref} head-ref={args.head_ref}')
    baseRefDir = args.base_ref
    headRefDir = args.head_ref
    headSha = args.head_sha
    modifiedFiles = getChangedMicroserviceFiles(baseRefDir, headRefDir)
    log('modifiedFiles', f'modifiedFiles={modifiedFiles}')

    for file in modifiedFiles:
        newtags, oldtags, newRelicAppName = getUpdatedTags(headRefDir, baseRefDir, file)
        log('imageTags', f'file={file} newtags={newtags} oldtags={oldtags}')

        deploymentType = 'ROLLING' if not oldtags else 'CANARY'

        for tag in newtags:
            pushToNewRelic(newRelicAppName, tag, deploymentType, headSha)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='This program pushes deployment info to new Relic')
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
        '--head-sha', 
        required=True,
        type=str,
        help='sha of the head reference')
    
    
    args = parser.parse_args()
    main(args)
