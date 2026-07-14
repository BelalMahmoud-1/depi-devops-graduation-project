# AWS Infrastructure Setup with Terraform (EKS, VPC, ECR)

![Terraform Architecture Diagram](diagrams/terraform.png)

## Overview

This repository contains the Infrastructure as Code (IaC) written in **Terraform** to provision a highly available, secure, and scalable microservices environment on AWS. The architecture is modularized to ensure reusability and follows AWS best practices, heavily utilizing IAM Roles for Service Accounts (IRSA) to maintain the principle of least privilege.

The infrastructure is broken down into several logical steps:

---

## 1. Networking (VPC Module)

Before provisioning any servers or clusters, we established a secure network foundation using Amazon Virtual Private Cloud (VPC). This module creates a VPC, an Internet Gateway for outbound/inbound internet access, and Public Subnets distributed across multiple Availability Zones for High Availability. 

**Key Configuration:** The subnets are specifically tagged with `kubernetes.io/role/elb = "1"` to allow the AWS Load Balancer Controller to discover them and provision Application Load Balancers automatically.

### Associated Terraform Code (`modules/vpc/main.tf`):
```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                                                    = "${var.project_name}-${var.environment}-public-${count.index + 1}"
    "kubernetes.io/role/elb"                                                = "1"
    "kubernetes.io/cluster/${var.project_name}-${var.environment}-cluster"  = "shared"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
```

---

## 2. Container Registry (ECR Module)

To support CI/CD pipelines and store Docker images securely, we created Amazon Elastic Container Registries (ECR) for the Frontend and Backend applications. 

**Security Note:** `scan_on_push` is enabled to automatically perform vulnerability scans on images as soon as they are pushed.

### Associated Terraform Code (`modules/ecr/main.tf`):
```hcl
resource "aws_ecr_repository" "backend" {
  name                 = "${var.project_name}-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project_name}-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}
```

---

## 3. Compute (EKS Control Plane & Worker Nodes)

The core compute engine is an Amazon Elastic Kubernetes Service (EKS) cluster. This section is divided into two parts:
1. **The Control Plane:** Managed by AWS. We create an IAM Role granting EKS permissions to manage AWS resources.
2. **The Worker Nodes (Node Group):** The EC2 instances running our application pods. We assign them an IAM Node Role with policies allowing them to join the cluster, manage network interfaces (CNI), and pull images from ECR.

### Associated Terraform Code (`modules/eks/main.tf` snippet):
```hcl
# --- EKS Cluster Control Plane ---
resource "aws_iam_role" "cluster" {
  name = "${var.project_name}-${var.environment}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_eks_cluster" "main" {
  name     = "${var.project_name}-${var.environment}-cluster"
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids             = var.public_subnet_ids
    endpoint_public_access = true
  }
}

# --- EKS Worker Nodes ---
resource "aws_iam_role" "node" {
  name = "${var.project_name}-${var.environment}-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}
resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}
resource "aws_iam_role_policy_attachment" "node_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.project_name}-${var.environment}-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.public_subnet_ids
  instance_types  = var.node_instance_types
  capacity_type   = "ON_DEMAND"

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }
}
```

---

## 4. Security & Add-ons (OIDC, IRSA, ALB, & EBS CSI)

To avoid giving overly broad permissions to the entire EC2 Worker Node Group, we utilize **IAM Roles for Service Accounts (IRSA)**. This adheres to the principle of least privilege. By provisioning an **OIDC Provider**, we can map AWS IAM Roles directly to specific Kubernetes Service Accounts (e.g., the ALB Controller pod).

We install two major add-ons:
1. **AWS Load Balancer Controller:** Provisioned via Helm to automatically create Application Load Balancers for our Kubernetes Ingress resources.
2. **EBS CSI Driver:** Allows Kubernetes to dynamically provision persistent block storage volumes for stateful applications.

### Associated Terraform Code (`modules/eks/main.tf` & root `main.tf`):
```hcl
# --- OIDC Provider Setup ---
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# --- IRSA for AWS Load Balancer Controller ---
data "aws_iam_policy_document" "alb_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "aws_iam_role" "alb_controller" {
  name               = "${var.project_name}-${var.environment}-alb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.alb_assume_role.json
}

# --- Helm Release: AWS Load Balancer Controller (From root main.tf) ---
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.eks.alb_controller_role_arn
  }
}

# --- EBS CSI Driver Add-on & IRSA ---
resource "aws_iam_role" "ebs_csi" {
  name               = "${var.project_name}-${var.environment}-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = aws_iam_role.ebs_csi.arn
}
```
