# 🛒 Amazona — DevOps Graduation Project

A fully containerized, cloud-native e-commerce application deployed on **AWS EKS** using modern DevOps practices.

---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Tech Stack](#tech-stack)
- [Architecture Diagram](#architecture-diagram)
- [Project Structure](#project-structure)
- [Docker Setup](#docker-setup)
- [Terraform Infrastructure](#terraform-infrastructure)
- [Kubernetes Manifests](#kubernetes-manifests)
- [How to Deploy](#how-to-deploy)
- [How to Destroy](#how-to-destroy)

---

## 🎯 Project Overview

Amazona is a 3-tier e-commerce application consisting of:

- **Frontend** — React.js served via Nginx
- **Backend** — Node.js/Express REST API
- **Database** — MongoDB Replica Set (3 nodes)

All components are containerized with Docker, orchestrated on Kubernetes (EKS), and provisioned with Terraform.

---

## 🧰 Tech Stack

| Layer | Technology |
|---|---|
| Frontend | React.js, Nginx |
| Backend | Node.js, Express |
| Database | MongoDB 7 (Replica Set) |
| Containerization | Docker, Docker Compose |
| Container Registry | AWS ECR |
| Orchestration | Kubernetes (AWS EKS) |
| Infrastructure as Code | Terraform |
| Load Balancer | AWS ALB (Application Load Balancer) |
| Storage | AWS EBS (gp2) |
| IAM Auth | OIDC + IRSA |

---

## 🏗️ Architecture Diagram

![Architecture Diagram](./architecture-diagram.png)

### Traffic Flow

```
User → AWS ALB → Amazona Ingress
                      ├── /* → Frontend Service (port 80) → React pods
                      └── /api/* → Backend Service (port 5000) → Node.js pods
                                                                      └── MongoDB StatefulSet (rs0)
                                                                               ├── mongo-0 (PRIMARY)
                                                                               ├── mongo-1 (SECONDARY)
                                                                               └── mongo-2 (SECONDARY)
```

### Key Components

**Inside EKS Cluster (namespace: default)**
- Frontend Deployment — 2 replicas, pulls image from ECR
- Backend Deployment — 2 replicas, pulls image from ECR
- MongoDB StatefulSet — 3 replicas with EBS gp2 persistent storage
- Amazona Ingress — routes traffic to frontend and backend
- backend-secrets — Kubernetes Secret holding `MONGODB_URL` and `JWT_SECRET`

**kube-system namespace**
- AWS Load Balancer Controller — manages ALB creation
- EBS CSI Controller + Node DaemonSet — manages EBS volume provisioning
- CoreDNS — internal DNS resolution

**AWS Services**
- ECR — stores `amazona-backend` and `amazona-frontend` images
- ALB — internet-facing load balancer
- EBS Volumes — 3 gp2 volumes for MongoDB persistence
- OIDC Provider + IAM Roles (IRSA) — secure pod-level AWS permissions

---

## 📁 Project Structure

```
depi-devops-graduation-project/
├── backend/                    # Node.js backend
│   ├── Dockerfile              # Multi-stage Docker build
│   └── package.json
├── frontend/                   # React frontend
│   ├── Dockerfile              # Multi-stage Docker build (Nginx)
│   ├── nginx.conf              # Nginx reverse proxy config
│   └── package.json
├── k8s/                        # Kubernetes manifests
│   ├── mongo-statefulset.yaml  # MongoDB StatefulSet (3 replicas)
│   ├── mongo-service.yaml      # mongo + mongo-headless services
│   ├── backend-deployment.yaml # Backend Deployment (2 replicas)
│   ├── backend-service.yaml    # Backend ClusterIP service
│   ├── frontend-deployment.yaml# Frontend Deployment (2 replicas)
│   ├── frontend-service.yaml   # Frontend ClusterIP service
│   └── ingress.yaml            # ALB Ingress
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                 # Root module (providers + modules + ALB helm)
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   └── modules/
│       ├── vpc/                # VPC, Subnets, Internet Gateway
│       ├── eks/                # EKS Cluster, Node Group, OIDC, IRSA
│       └── ecr/                # ECR repositories
├── docker-compose.yml          # Local development setup
└── deploy.sh                   # Automated deployment script
```

---

## 🐳 Docker Setup

### Build locally

```bash
docker-compose build
```

### Run locally

```bash
docker-compose up -d
docker-compose ps
```

### Services

| Service | Port | Description |
|---|---|---|
| frontend | 3000 | React app |
| backend | 5000 | REST API |
| mongo | 27017 | MongoDB |

### Verify

```bash
curl http://localhost:5000/api/health
```

---

## ☁️ Terraform Infrastructure

Terraform provisions the complete AWS infrastructure across 3 modules:

### Modules

**vpc/**
- AWS VPC (`10.0.0.0/16`)
- 2 Public Subnets across 2 AZs (`us-east-1a`, `us-east-1b`)
- Internet Gateway + Route Tables

**eks/**
- EKS Cluster (`amazona-dev-cluster`, Kubernetes v1.31)
- Managed Node Group — 2x `t3.small` (min 1, max 3)
- IAM Roles for cluster and nodes
- OIDC Provider for IRSA
- EBS CSI Driver addon
- IRSA roles for EBS CSI and ALB Controller

**ecr/**
- `amazona-backend` repository
- `amazona-frontend` repository

**Root (main.tf)**
- AWS Load Balancer Controller — installed via Helm automatically
- EBS CSI ServiceAccount annotation

### Key Variables (`variables.tf`)

| Variable | Default | Description |
|---|---|---|
| `aws_region` | `us-east-1` | AWS region |
| `project_name` | `amazona` | Project name prefix |
| `environment` | `dev` | Environment name |
| `vpc_cidr` | `10.0.0.0/16` | VPC CIDR block |
| `eks_cluster_version` | `1.31` | Kubernetes version |
| `eks_node_instance_types` | `t3.small` | Node instance type |
| `eks_node_desired_size` | `2` | Desired number of nodes |

### Outputs

```bash
terraform output
# vpc_id
# eks_cluster_name
# eks_cluster_endpoint
# alb_controller_role_arn
# backend_ecr_url
# frontend_ecr_url
```

---

## ⚙️ Kubernetes Manifests

### MongoDB StatefulSet (`k8s/mongo-statefulset.yaml`)
- 3 replicas with stable pod names (`mongo-0`, `mongo-1`, `mongo-2`)
- Each pod has a 2Gi EBS gp2 PVC
- Replica Set: `mongo-0` = PRIMARY, `mongo-1/2` = SECONDARY

### Backend Deployment (`k8s/backend-deployment.yaml`)
- 2 replicas pulling from ECR
- Reads `MONGODB_URL` and `JWT_SECRET` from Kubernetes Secret
- Readiness/Liveness probes on `/api/products`

### Frontend Deployment (`k8s/frontend-deployment.yaml`)
- 2 replicas pulling from ECR
- Served by Nginx on port 80
- API requests proxied to backend service

### Ingress (`k8s/ingress.yaml`)
- AWS ALB (internet-facing)
- `/api/*` → Backend Service (port 5000)
- `/*` → Frontend Service (port 80)

---

## 🚀 How to Deploy

### Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform >= 1.0
- kubectl
- Helm 3
- Docker

### Step 1 — Provision Infrastructure

```bash
cd terraform/
terraform init
terraform apply -auto-approve
```

This creates:
- VPC + Subnets
- EKS Cluster + Node Group
- ECR repositories
- ALB Controller (via Helm)
- IRSA roles

### Step 2 — Deploy Application

```bash
cd ..
./deploy.sh
```

The script automatically:
1. Updates kubeconfig for the new cluster
2. Logs in to ECR and pushes images
3. Creates Kubernetes secrets
4. Applies all K8s manifests
5. Waits for MongoDB to be ready
6. Initializes MongoDB Replica Set
7. Restarts backend to connect to MongoDB
8. Prints the ALB URL

### Step 3 — Access the Application

```bash
# Get the ALB URL
kubectl get ingress amazona-ingress

# Health check
curl http://<ALB_URL>/api/health
# Expected: {"status":"healthy"}
```

---

## 🗑️ How to Destroy

```bash
# Delete ingress first (removes ALB)
kubectl delete ingress amazona-ingress
sleep 60

# Destroy all infrastructure
cd terraform/
terraform destroy -auto-approve
```

> ⚠️ Make sure to delete the ingress before running `terraform destroy` to avoid VPC dependency errors.

---

## 👥 Team

DEPI DevOps Graduation Project — 2026
