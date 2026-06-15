ARGO_URL="https://argocd.integrator.io"
echo "Enter Argo cd acess token : "
read -s ARGOCD_TOKEN

cd manifests
for f in *
do 
    echo $f
    curl -X POST $ARGO_URL/api/v1/projects --insecure -H "Authorization: Bearer $ARGOCD_TOKEN" -H "Content-Type: application/json" -d @$f
done