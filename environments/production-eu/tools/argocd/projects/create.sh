echo "Enter Argocd URL with https:// and without / at end:"
read ARGO_URL
echo "Enter Argo cd acess token : "
read -s ARGOCD_TOKEN

cd manifests
for f in *
do 
    echo $f
    curl -X POST $ARGO_URL/api/v1/projects --insecure -H "Authorization: Bearer $ARGOCD_TOKEN" -H "Content-Type: application/json" -d @$f
done