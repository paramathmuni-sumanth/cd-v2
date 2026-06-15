#!/bin/bash
#Taking inputs
echo "Enter write access Git Token: "
read -s GIT_PAT_WRITE
echo "Enter Argo cd acess token : "
read -s ARGOCD_TOKEN
source global-env.conf
source $1

echo "Are you sure want to delete $APPLICATION_NAME? (yes/no):"
read DELETE_CONFIRMATION
if [ $DELETE_CONFIRMATION != "yes" ]
then
    exit 1
else
    echo "Deleting $APPLICATION_NAME as per your confirmation"
fi

#Cloning Git Repo
git clone -b $GIT_BRANCH https://$GIT_PAT_WRITE@github.com/$GITHUB_ORG/$CD_REPO
echo 'successfully cloned the repository '

## checking existence of manifest
cd $CD_REPO
mkdir -p $PROJECT_TYPE
cd $PROJECT_TYPE
ls
if [ -d $APPLICATION_NAME ] 
then
    echo "removing service folder"
    rm -rf $APPLICATION_NAME  
else
    echo "This service doesnot exist"
    cd ..
    rm -rf $CD_REPO
    exit 1
fi

#pushing to git
cd ..
git pull
git add .
git commit -m "offboarded $APPLICATION_NAME"
git push

#removing git clone
echo "removing git clone"
cd ..
rm -rf $CD_REPO


# Deleting application
curl -X DELETE $ARGO_URL/api/v1/applications/{"$APPLICATION_NAME"} --insecure -H "Authorization: Bearer $ARGOCD_TOKEN" -H "Content-Type: application/json" 

echo "application offboarded successfully"