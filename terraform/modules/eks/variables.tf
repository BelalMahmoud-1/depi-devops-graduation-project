variable "project_name" {}
variable "environment" {}
variable "vpc_id" {}
variable "public_subnet_ids" { type = list(string) }
variable "cluster_version" {}
variable "node_instance_types" { type = list(string) }
variable "node_desired_size" {}
variable "node_min_size" {}
variable "node_max_size" {}
