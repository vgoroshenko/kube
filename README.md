## Terraform Kubernetes manage + Vault ##

Build for update cluster and deployments config

1. In Dockerfile we install dependencies: 
terraform, kubectl, jq, curl, aws-iam-authenticator, awscli

2. Using Vault set aws creds for download tfstate and apply terraform config (if builder doesn't have IAM role)

3. Terraform initializes tfstate file from s3 bucket, applies config and stores to s3 bucket

 3.1 Terraform creates Cognito (mln-cognito-up) + Lambda function, EKS cluster (mln-kube-cluster-dev), VPC (mln-kube-vpc-dev)
 
  3.1.1 In EKS we have 2 nodes t3.small (dev), 2 load balancer (mlncs, mlnui), volume 12Gb (dev) 
  
  3.1.2 In deployments we have 2 replicas for every service (mlncs, mlnui) and 1 replicas for mln-redis

4. Write kubernetes config to Vault for store state

5. Write url to Vault for updating kubernetes deployment (bamboo creates image for mlncs or mlnui and pushes by using url from Vault)

