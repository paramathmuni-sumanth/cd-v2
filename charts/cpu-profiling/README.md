## please make sure below things are in place
- s3 bucket celigo-k8s-<env>-infra-tasks exists
- iam role attached with service account to access s3
- ASGs are attached with MongoDB Atlas Security Group
- SSH KEY, KnownHosts and MongoDB URI are configured in secrets
- Base image have cross-account-access