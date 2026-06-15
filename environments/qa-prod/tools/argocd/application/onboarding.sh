#!/bin/bash
#Taking inputs

echo "Enter write access Git Token: "
read -s GIT_PAT_WRITE
echo "Enter Argo cd acess token : "
read -s ARGOCD_TOKEN
source global-env.conf
source $1

#Cloning Git Repo
git clone -b $GIT_BRANCH https://$GIT_PAT_WRITE@github.com/$GITHUB_ORG/$CD_REPO
echo 'successfully cloned the repository'

## checking existence of manifest
cd $CD_REPO
mkdir -p $PROJECT_TYPE
cd $PROJECT_TYPE
if [ -d $APPLICATION_NAME ] 
then
    echo "This microservice already exist in git"
    cd ../..
    rm -rf $CD_REPO
    exit 1
else
    mkdir $APPLICATION_NAME
fi

#configuring istio host
echo "configuring istio host"
ISTIO_HOST="$APPLICATION_NAME.celigo.io"
if [ $PROJECT_TYPE == "ia" ]
then
    ISTIO_HOST="$APPLICATION_NAME.ia.celigo.io"
fi

#create values file for microservice
cp ../template-values/microservice.yaml $APPLICATION_NAME
cd $APPLICATION_NAME

echo 'updating microservice.yaml file'
NAME="$APPLICATION_NAME"  yq -i e '.microservice.common.image.name=env(NAME) ' microservice.yaml
PORT="$CONTAINER_PORT" yq -i e '.microservice.deployment.containerPort=env(PORT) ' microservice.yaml
VERSION="$IMAGE_TAG" yq -i e '.microservice.deployment.image.tag=env(VERSION) ' microservice.yaml
HOST="$ISTIO_HOST" yq -i e '.microservice.virtualService.hosts +=env(HOST) ' microservice.yaml
NEW_RELIC_APP_NAME="$GIT_BRANCH-$APPLICATION_NAME"
NEW_RELIC=$NEW_RELIC_APP_NAME yq -i e '.microservice.env.NEW_RELIC_APP_NAME=env(NEW_RELIC) ' microservice.yaml
SERVICE_ACCOUNT_ANNOTATION=$(echo {"eks.amazonaws.com/role-arn": "arn:aws:iam::$ACCOUNT_ID:role/$APPLICATION_NAME-s3-role-k8s"} )
ANNOTATION=$SERVICE_ACCOUNT_ANNOTATION yq -i e '.microservice.serviceAccount.annotations +=env(ANNOTATION) ' microservice.yaml

if [ $PROJECT_TYPE == "ui" ]
then
    yq -i e '.microservice.virtualService.hosts[0]="*" ' microservice.yaml
    yq -i e '.microservice.virtualService.gateways=[ "istio-gateway/istio-in-gw-integ" ] ' microservice.yaml
fi

if [ $PROJECT_TYPE == "io" ]
then
    PORT="$CONTAINER_PORT" yq -i e '.microservice.deploymentFree.containerPort=env(PORT) ' microservice.yaml
    VERSION="$IMAGE_TAG" yq -i e '.microservice.deploymentFree.image.tag=env(VERSION) ' microservice.yaml
    ENABLE="true" yq -i e '.microservice.common.subscriptionType.enabled=env(ENABLE) ' microservice.yaml
fi

if [ $PROJECT_TYPE != "io" ]
then
    yq -i e 'del(.microservice.deploymentFree)' microservice.yaml
fi

#creating application manifest
application=$(cat <<EOF
{
  "apiVersion": "argoproj.io/v1alpha1",
  "kind": "Application",
  "metadata": {
    "name": "$APPLICATION_NAME",
    "namespace": "argocd",
    "finalizers": [
      "resources-finalizer.argocd.argoproj.io"
    ]
  },
  "spec": {
    "project": "$PROJECT_TYPE",
    "source":{
      "helm":{
        "valueFiles": [
        "../../$PROJECT_TYPE/$APPLICATION_NAME/microservice.yaml"
        ]
      },
      "path": "charts/microservice",
      "repoURL": "https://github.com/$GITHUB_ORG/$CD_REPO.git",
      "targetRevision": "$GIT_BRANCH"
    },
    "destination":{
      "namespace": "$PROJECT_TYPE",
      "server": "https://kubernetes.default.svc"
    },
    "syncPolicy":{
      "automated":{
        "prune": true,
        "selfHeal": true
      },
      "syncOptions": [
        "CreateNamespace=true"
      ]
    }
  }
}
EOF
)
echo "$application" > argo_app_manifest.json
cat argo_app_manifest.json

#pushing to git
cd ../../
git pull
git add .
git commit -m "onboarded $APPLICATION_NAME"
git push

# Creating application
cd $PROJECT_TYPE/$APPLICATION_NAME

curl -X POST $ARGO_URL/api/v1/applications --insecure -H "Authorization: Bearer $ARGOCD_TOKEN" -H "Content-Type: application/json" -d @argo_app_manifest.json

echo "successfully application onboarded"

#removing git clone
echo "removing git clone"
cd ../../..
rm -rf $CD_REPO