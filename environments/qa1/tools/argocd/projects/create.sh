ARGO_URL="https://a7ff5b286980d47678d4f9b11b9e7375-1530618177.ap-south-1.elb.amazonaws.com"
echo "Enter Argo cd acess token : "
read -s ARGOCD_TOKEN

cd manifests
for f in *
do 
    echo $f
    curl -X POST $ARGO_URL/api/v1/projects --insecure -H "Authorization: Bearer $ARGOCD_TOKEN" -H "Content-Type: application/json" -d @$f
done