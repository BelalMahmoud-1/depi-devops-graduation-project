variable "aws_region" {
  default = "us-east-1"
}
variable "project_name" {
  default = "amazona"
}
variable "eks_cluster_version" {
  default = "1.31"
}
variable "eks_node_instance_type" {
  default = "t3.small"
}
variable "eks_node_min" {
  default = 1
}
variable "eks_node_max" {
  default = 3
}
variable "eks_node_desired" {
  default = 2
}
