
provider "aws" {
  region     = var.region
}
terraform {
  backend "s3" {
    bucket = "mlnbucket-eu-central"
    key = "terraform/terraform.tfstate"
    region = "eu-central-1"
  }
}
locals {
  cluster_name = var.cluster_name
}
module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  vpc_id       = module.vpc.vpc_id
  cluster_name    = local.cluster_name
  cluster_version = "1.20"
  subnets         = module.vpc.private_subnets
  cluster_endpoint_public_access = true

  node_groups = {
    eks_nodes = {
      instance_types = [var.instance_type]
      capacity_type = "ON_DEMAND"
      desired_capacity = 2
      disk_size = 13
      public_ip = true
      key_name = "kube"
      additional_security_group_ids = [aws_security_group.eks_cluster.id]
      k8s_labels = {
        Environment = "test"
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }
      additional_tags = {
        ExtraTag = "example"
      }
    }
  }
  tags = {Name = var.cluster_name}
  manage_aws_auth = false
}
data "aws_availability_zones" "available" {
}
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"

  name                 = var.vpc_name
  cidr                 = "172.16.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
  public_subnets       = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support = true
  enable_vpn_gateway = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}
