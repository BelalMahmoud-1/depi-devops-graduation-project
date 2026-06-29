# DEPI DevOps Graduation Project - Infrastructure

## Architecture

![Infrastructure Flow](screenshots\flowww.png)

---

# Project Overview

This repository contains the Infrastructure as Code (IaC) implementation for the DEPI DevOps Graduation Project. The infrastructure is fully automated using Terraform on Amazon Web Services (AWS) following a modular architecture.

The project provisions:

- Amazon VPC
- Public, Private, and Database Subnets
- Internet Gateway
- NAT Gateway
- Route Tables
- Amazon EKS Cluster
- Managed Node Group
- Amazon ECR
- Amazon S3
- Amazon CloudFront

---

# Technology Stack

| Technology | Purpose |
|------------|---------|
| Terraform | Infrastructure as Code |
| AWS | Cloud Provider |
| Amazon VPC | Networking |
| Amazon EKS | Kubernetes Cluster |
| Amazon ECR | Container Registry |
| Amazon S3 | Object Storage |
| Amazon CloudFront | Content Delivery Network |
| Git | Version Control |
| GitHub | Source Code Management |

---

# Project Structure

```text
depi-terraform-project-1/
│
├── .gitignore
├── README.md
├── backend.tf
├── providers.tf
├── variables.tf
├── terraform.tfvars
├── outputs.tf
├── main.tf
├── .terraform.lock.hcl
├── flowww.png
│
└── modules/
    ├── vpc/
    ├── eks/
    ├── ecr/
    └── s3-cloudfront/
```

---

# Prerequisites

Before deploying the infrastructure, install the following tools:

- AWS CLI
- Terraform (>= 1.5)
- kubectl
- Git

---

# Configure AWS CLI

```bash
aws configure
```

---

# Initialize Terraform

```bash
terraform init
```

---

# Validate Configuration

```bash
terraform validate
```

---

# Format Terraform Files

```bash
terraform fmt -recursive
```

---

# Review Infrastructure Changes

```bash
terraform plan
```

---

# Deploy Infrastructure

```bash
terraform apply
```

---

# Destroy Infrastructure

```bash
terraform destroy
```

---

# Terraform Modules

## VPC Module

Creates:

- Amazon VPC
- Public Subnets
- Private Subnets
- Database Subnets
- Internet Gateway
- NAT Gateway
- Route Tables

---

## EKS Module

Creates:

- Amazon EKS Cluster
- Managed Node Group
- IAM Roles
- Security Groups

---

## ECR Module

Creates:

- Amazon Elastic Container Registry Repository

---

## S3 + CloudFront Module

Creates:

- Amazon S3 Bucket
- Amazon CloudFront Distribution
- Origin Access Control (OAC)

---

# Git Workflow

```text
main
 │
 └── dev
      │
      ├── feature/user1
      ├── feature/user2
      └── feature/user3
```

Create a feature branch:

```bash
git checkout dev
git pull
git checkout -b feature/your-feature
```

Commit changes:

```bash
git add .
git commit -m "feat: description"
git push origin feature/your-feature
```

Create a Pull Request into the **dev** branch.

---

# Remote Backend

Terraform state is stored remotely in Amazon S3.

Example:

```hcl
terraform {
  backend "s3" {
    bucket = "depi-terraform-state-962639302575"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}
```

---

# Common Terraform Commands

```bash
terraform init
terraform validate
terraform fmt
terraform plan
terraform apply
terraform destroy
terraform output
terraform state list
```

---

# Amazon EKS Commands

```bash
aws eks update-kubeconfig \
--region us-east-1 \
--name depi-graduation-dev
```

```bash
kubectl get nodes
```

---

# Terraform Outputs

After a successful deployment, Terraform provides outputs such as:

- vpc_id
- eks_cluster_name
- eks_cluster_endpoint
- ecr_repository_url
- s3_bucket_name
- cloudfront_domain_name

---

# Best Practices

- Never commit `.terraform/`
- Never commit `terraform.tfstate`
- Never commit `*.tfplan`
- Always run `terraform fmt`
- Always run `terraform validate`
- Always review `terraform plan`
- Keep infrastructure modular
- Use remote state for team collaboration

---

# License

This project was developed as part of the DEPI DevOps Graduation Project for educational purposes.