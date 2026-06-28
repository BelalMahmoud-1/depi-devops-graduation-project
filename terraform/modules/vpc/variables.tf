variable "project_name" {}
variable "environment" {}
variable "vpc_cidr" {}
variable "availability_zones" { type = list(string) }
variable "public_subnet_cidrs" { type = list(string) }
