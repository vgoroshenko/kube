variable "region" {
  default = "eu-central-1"
}
variable "instance_type" {
  default = "t3.small"
}
variable "access_key" {
  default = ""
}
variable "secret_key" {
  default = ""
}
variable "account_id" {
  default = "111111111111"
}
#velox registry
variable "docker_registry" {
  default = "111111111111.dkr.ecr.eu-central-1.amazonaws.com"
}
variable "nodes_sg_name" {
  default = "mln-kube-ng-sg-prod_env"
}
variable "cluster_sg_name" {
  default = "mln-kube-cluster-sg-prod_env"
}
variable "eks_node_name" {
  default = "mln-kube-ng-prod_env"
}
variable "cluster_name" {
  default = "mln-kube-cluster-prod_env"
}
variable "vpc_name" {
  default = "mln-kube-vpc-prod_env"
}
variable "s3_bucket_name" {
  default = "mlnbucket-eu-central"
}
variable "kubeconfig_secret_name" {
  default = "secret/data/build/k8s/mln/mln-kube-cluster-prod_env_kubeconfig"
}
variable "kube_url_secret_name" {
  default = "secret/data/build/k8s/mln/url/prod_env"
}
variable "mln_cognito_name" {
  default = "mln_cognito_up_prod_env"
}
variable "lambda_function_name" {
  default = "email-verified-prod_env"
}
