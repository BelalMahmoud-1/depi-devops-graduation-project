variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "amazona"
}

variable "environment" {
  default = "dev"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "eks_cluster_version" {
  default = "1.31"
}

variable "eks_node_instance_types" {
  default = ["t3.small"]
}

variable "eks_node_desired_size" {
  default = 2
}

variable "eks_node_min_size" {
  default = 1
}

variable "eks_node_max_size" {
  default = 3
}
