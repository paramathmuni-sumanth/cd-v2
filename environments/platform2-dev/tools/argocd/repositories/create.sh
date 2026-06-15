echo "Enter Argocd URL with https:// and without / at end:"
read ARGO_URL
echo "Enter Argo cd acess token : "
read -s ARGOCD_TOKEN
echo "Enter read access Git Token: "
read -s GIT_PAT_READ
echo "Enter bot username: "
read -s GIT_BOT_USER

cd manifests
for f in *
do 
    echo $f
    type=$(jq -r '.type' $f)
    echo $type
    echo "\n"
    if [ $type == "helm" ]
    then
        jq --arg a "${GIT_BOT_USER}" '.username = $a' $f > "tmp" && mv "tmp" $f
    fi
    jq --arg a "${GIT_PAT_READ}" '.password = $a' $f > "tmp" && mv "tmp" $f
    curl -X POST $ARGO_URL/api/v1/repositories --insecure -H "Authorization: Bearer $ARGOCD_TOKEN" -H "Content-Type: application/json" -d @$f
    if [ $type == "helm" ]
    then
        jq --arg a "" '.username = $a' $f > "tmp" && mv "tmp" $f
    fi
    jq --arg a "" '.password = $a' $f > "tmp" && mv "tmp" $f
done
