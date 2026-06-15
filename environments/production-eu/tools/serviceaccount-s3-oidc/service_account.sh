# check if the number of arguments is not 3
if [ "$#" -ne 3 ]; then
  # print an error message and exit
  echo "Error: script requires exactly 3 arguments" >&2
  exit 1
fi

namespace=$1
microservice=$2
microservice_s3_folder=$3
new_env="production-eu"
account_id="860378520032"
aws_region="eu-central-1"
oidc_id="F056B28D1BDBCD7D326AE4088EBDD66C"
profile="default"

s3_policy=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::celigo-k8s-$new_env-env-vars"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::celigo-k8s-$new_env-env-vars/$microservice_s3_folder/*"
            ]
        }
    ]
 }
EOF
)

echo "$s3_policy";

echo "$s3_policy" > $microservice-s3-policy-k8s.json

trust_policy=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Principal": {
          "Federated": "arn:aws:iam::$account_id:oidc-provider/oidc.eks.$aws_region.amazonaws.com/id/$oidc_id"
        },
        "Effect": "Allow",
        "Condition": {
          "StringEquals": {
            "oidc.eks.$aws_region.amazonaws.com/id/$oidc_id:sub": "system:serviceaccount:$namespace:$microservice"
          }
        }
      }
    ]
  }
EOF
)

echo "$trust_policy";

echo "$trust_policy" > $microservice-trust-policy-k8s.json

aws iam create-policy --policy-name $microservice-s3-policy-k8s --policy-document file://$microservice-s3-policy-k8s.json --profile $profile
aws iam create-role --role-name $microservice-s3-role-k8s --assume-role-policy-document file://$microservice-trust-policy-k8s.json --profile $profile
aws iam attach-role-policy --role-name $microservice-s3-role-k8s --policy-arn arn:aws:iam::$account_id:policy/$microservice-s3-policy-k8s --profile $profile