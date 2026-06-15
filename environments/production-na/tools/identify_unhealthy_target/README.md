
  # Cronjob to identify unhealthy targets in NLB 

    Cronjob, configmap and rbac included in this directly to identify the unhealthy targets in the give NLB and respective target groups.


    Note: I have included the Dockerfile, which is used to build the docker image used in the cronjob, nowhere it related to implementation.

  ## Prerequisites 
  Need to create IAM role for Cronjob.

  Name: identify_unhealthy_target

  TrustPolicy:

    ```{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "<<OIDC ARN>>"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.<<REGION>>.amazonaws.com/id/<<OIDC VALUE>>:sub": "system:serviceaccount:default:identify-unhealthy-target"
                }
            }
        }
    ]
}

Managed Policy: [ Need to be attached with IAM role]

```{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeTargetHealth",
                "elasticloadbalancing:DescribeTargetGroups"
            ],
            "Resource": "*"
        }
    ]
}
```

Ensure you are able to access the EKS cluster before you execute the script

## Execution
Ensure NLB arn, region, and AWS account number has been updated in the yaml based on environment, before execute this yaml in EKS cluster.