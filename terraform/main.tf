terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
}

module "eks" {
  source                 = "./modules/eks"
  project_name           = var.project_name
  eks_cluster_version    = var.eks_cluster_version
  eks_node_instance_type = var.eks_node_instance_type
  eks_node_desired       = var.eks_node_desired
  eks_node_max           = var.eks_node_max
  eks_node_min           = var.eks_node_min
}
