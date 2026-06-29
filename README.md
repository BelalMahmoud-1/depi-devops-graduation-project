# 🛒 Amazona — DevOps Graduation Project

<div align="center">

![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![React](https://img.shields.io/badge/React-61DAFB?style=for-the-badge&logo=react&logoColor=black)

**Full-stack e-commerce application deployed on AWS EKS using modern DevOps practices.**

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Technology Stack](#-technology-stack)
- [Project Structure](#-project-structure)
- [Quick Start](#-quick-start)
- [Infrastructure (Terraform)](#-infrastructure-terraform)
- [Kubernetes Manifests](#-kubernetes-manifests)
- [Docker & Local Development](#-docker--local-development)
- [Deployment](#-deployment)
- [Teardown](#-teardown)

---

## 🌟 Overview

Amazona is a full-stack e-commerce platform built with a **3-tier architecture** and deployed on **AWS EKS** using Infrastructure as Code (Terraform), containerization (Docker), and container orchestration (Kubernetes).

| Component | Technology | Replicas |
|-----------|-----------|---------|
| Frontend | React.js + Nginx | 2 pods |
| Backend | Node.js + Express | 2 pods |
| Database | MongoDB Replica Set | 3 pods |

---

## 🏗️ Architecture

```
                         ┌─────────────────────────────────────────────┐
                         │           AWS EKS Cluster                   │
                         │  ┌──────────────────────────────────────┐   │
User ──► AWS ALB ──► Ingress│  Frontend Deployment (2 replicas)    │   │
                         │  │  ┌──────────┐  ┌──────────┐         │   │
         /* ────────────►│  │  │ React pod│  │ React pod│         │   │
         /api/* ─────────┼──┼─►│          │  │          │         │   │
                         │  │  └──────────┘  └──────────┘         │   │
                         │  │                    ▲                 │   │
                         │  │             Frontend svc             │   │
                         │  └──────────────────────────────────────┘   │
                         │                                             │
                         │  ┌──────────────────────────────────────┐   │
                         │  │  Backend Deployment (2 replicas)     │   │
                         │  │  ┌──────────┐  ┌──────────┐         │   │
                         │  │  │Node.js   │  │Node.js   │         │   │
                         │  │  │ pod      │  │ pod      │         │   │
                         │  │  └──────────┘  └──────────┘         │   │
                         │  │                    ▲                 │   │
                         │  │             Backend svc              │   │
                         │  └──────────────────────────────────────┘   │
                         │                    │                        │
                         │  ┌─────────────────▼────────────────────┐   │
                         │  │  MongoDB StatefulSet (3 replicas)    │   │
                         │  │  ┌────────┐ ┌────────┐ ┌────────┐   │   │
                         │  │  │mongo-0 │ │mongo-1 │ │mongo-2 │   │   │
                         │  │  │PRIMARY │ │SECONDRY│ │SECONDRY│   │   │
                         │  │  └───┬────┘ └───┬────┘ └───┬────┘   │   │
                         │  │      │           │          │        │   │
                         │  │    PVC         PVC        PVC       │   │
                         │  │      │           │          │        │   │
                         │  │   EBS gp2    EBS gp2   EBS gp2     │   │
                         │  └──────────────────────────────────────┘   │
                         └─────────────────────────────────────────────┘
                                         │
                    ┌────────────────────┼───────────────────┐
                    │                    │                   │
                 AWS ECR            AWS EBS           S3 (TF State)
            (Docker Images)      (Persistent)      (Remote Backend)
```

---

## 🛠️ Technology Stack

| Category | Tool | Purpose |
|----------|------|---------|
| **Containerization** | Docker | Package application into containers |
| **Local Dev** | docker-compose | Run full stack locally |
| **IaC** | Terraform | Provision AWS infrastructure |
| **Cloud** | AWS EKS | Managed Kubernetes cluster |
| **Registry** | AWS ECR | Store Docker images |
| **Storage** | AWS EBS (gp2) | Persistent MongoDB storage |
| **Networking** | AWS ALB | Internet-facing load balancer |
| **Orchestration** | Kubernetes | Deploy and manage containers |
| **State Backend** | AWS S3 | Remote Terraform state storage |
| **Service Mesh** | Helm | Install ALB & EBS controllers |
| **Security** | IRSA + OIDC | Fine-grained IAM for K8s pods |

---

## 📁 Project Structure

```
depi-devops-graduation-project/
│
├── 📄 docker-compose.yml          # Local development stack
├── 📄 .env.example                # Environment variables template
├── 📄 deploy.sh                   # Automated deployment script
├── 📄 README.md                   # This file
│
├── 🐳 backend/                    # Node.js API Server
│   ├── Dockerfile                 # Multi-stage production build
│   ├── package.json
│   ├── package-lock.json          # Locked dependencies
│   └── src/
│
├── 🐳 frontend/                   # React.js Application
│   ├── Dockerfile                 # Multi-stage build + Nginx
│   ├── nginx.conf                 # Nginx configuration
│   ├── package.json
│   ├── package-lock.json          # Locked dependencies
│   └── src/
│
├── ☸️  k8s/                       # Kubernetes Manifests
│   ├── backend-deployment.yaml    # Backend Deployment (2 replicas)
│   ├── backend-service.yaml       # Backend ClusterIP Service
│   ├── frontend-deployment.yaml   # Frontend Deployment (2 replicas)
│   ├── frontend-service.yaml      # Frontend ClusterIP Service
│   ├── mongo-statefulset.yaml     # MongoDB StatefulSet (3 replicas)
│   ├── mongo-service.yaml         # MongoDB Headless + ClusterIP Services
│   ├── ingress.yaml               # ALB Ingress (/* → frontend, /api/* → backend)
│   ├── secrets.yaml               # Kubernetes Secrets template
│   └── hpa.yaml                   # Horizontal Pod Autoscaler
│
└── 🏗️  terraform/                 # Infrastructure as Code
    ├── main.tf                    # Root module + Helm ALB Controller
    ├── variables.tf               # Input variables
    ├── outputs.tf                 # Output values
    ├── backend.tf                 # S3 Remote State Backend
    ├── .gitignore                 # Ignore state files
    │
    └── modules/
        ├── vpc/                   # VPC + Subnets + IGW
        │   ├── main.tf
        │   ├── variables.tf
        │   └── outputs.tf
        │
        ├── eks/                   # EKS Cluster + Nodes + IRSA
        │   ├── main.tf            # Cluster, NodeGroup, OIDC, IRSA, EBS CSI
        │   ├── variables.tf
        │   ├── outputs.tf
        │   └── alb-policy.json    # ALB Controller IAM Policy
        │
        └── ecr/                   # ECR Repositories
            ├── main.tf
            ├── variables.tf
            └── outputs.tf
```

---

## ⚡ Quick Start

### Prerequisites

```bash
# Required tools
aws --version        # AWS CLI configured
terraform --version  # >= 1.5
kubectl version      # Kubernetes CLI
helm version         # Helm >= 3
docker --version     # Docker
```

### Run Locally (docker-compose)

```bash
# 1. Clone the repo
git clone https://github.com/BelalMahmoud-1/depi-devops-graduation-project.git
cd depi-devops-graduation-project

# 2. Setup environment
cp .env.example .env

# 3. Build & run
docker-compose build
docker-compose up -d

# 4. Access
open http://localhost:3000        # Frontend
curl http://localhost:5000/api/health  # Backend API

# 5. Stop
docker-compose down
```

---

## 🏗️ Infrastructure (Terraform)

### What Terraform Creates

| Resource | Details |
|----------|---------|
| **VPC** | 10.0.0.0/16 with 2 public subnets |
| **Subnets** | us-east-1a + us-east-1b |
| **Internet Gateway** | Public internet access |
| **EKS Cluster** | Kubernetes 1.31, public endpoint |
| **Node Group** | 2x t3.small EC2 instances |
| **ECR Repos** | amazona-backend + amazona-frontend |
| **IAM Roles** | Cluster role + Node role + IRSA roles |
| **OIDC Provider** | Enables IRSA |
| **EBS CSI Driver** | Auto-provision EBS volumes |
| **ALB Controller** | Manages AWS Load Balancers via Helm |
| **S3 Backend** | Remote state storage |

### Terraform Commands

```bash
cd terraform

# Initialize
terraform init

# Preview changes
terraform plan

# Apply (15-20 minutes)
terraform apply -auto-approve

# Destroy
terraform destroy -auto-approve
```

### Terraform Outputs

```bash
terraform output
# eks_cluster_name        = "amazona-dev-cluster"
# eks_cluster_endpoint    = "https://..."
# backend_ecr_url         = "608645726975.dkr.ecr.us-east-1.amazonaws.com/amazona-backend"
# frontend_ecr_url        = "608645726975.dkr.ecr.us-east-1.amazonaws.com/amazona-frontend"
# vpc_id                  = "vpc-..."
```

---

## ☸️ Kubernetes Manifests

### K8s Resources Overview

```bash
# Apply all manifests
kubectl apply -f k8s/

# Check everything
kubectl get pods,svc,ingress,pvc
```

### Key Design Decisions

**MongoDB StatefulSet** — Uses StatefulSet instead of Deployment because:
- Each pod needs a stable DNS name (`mongo-0.mongo-headless:27017`)
- Each pod needs persistent storage that survives restarts
- Pods start in order: `mongo-0` → `mongo-1` → `mongo-2`

**MongoDB Replica Set** — 3 nodes for high availability:
- `mongo-0`: PRIMARY (handles reads & writes)
- `mongo-1`: SECONDARY (hot standby)
- `mongo-2`: SECONDARY (hot standby)

**IRSA (IAM Roles for Service Accounts)** — Fine-grained permissions:
- ALB Controller → only permission to manage Load Balancers
- EBS CSI Driver → only permission to manage EBS volumes

---

## 🐳 Docker & Local Development

### Backend Dockerfile — Multi-Stage Build

```
Stage 1 (builder):  Install ALL deps → Compile ES6+ with Babel
Stage 2 (production): Copy compiled code → Install PROD deps only
```

Result: Smaller image, no dev tools in production.

### Frontend Dockerfile — Multi-Stage Build

```
Stage 1 (builder):  npm install → npm run build (React → static files)
Stage 2 (nginx):    Copy static files → Serve with Nginx
```

> ⚠️ `REACT_APP_API_URL` must be set at **build time** (baked into JS bundle).

### docker-compose Services

```
mongo     → MongoDB 7 (internal only, no host port)
backend   → Node.js API on port 5000
frontend  → Nginx on port 3000
```

Startup order: `mongo` (healthy) → `backend` (healthy) → `frontend`

---

## 🚀 Deployment

### Full Deployment (Terraform + K8s)

```bash
# Step 1: Provision infrastructure (~15-20 min)
cd terraform
terraform apply -auto-approve

# Step 2: Deploy application
cd ..
./deploy.sh
```

### What `deploy.sh` Does

```
1. Update kubeconfig for EKS
2. Login to ECR
3. Tag & push Docker images to ECR
4. Create Kubernetes secrets
5. Apply all K8s manifests
6. Wait for MongoDB pods to be ready
7. Initialize MongoDB Replica Set
8. Restart Backend deployment
9. Display ALB URL
```

### Useful Commands

```bash
# Monitor pods
kubectl get pods -w

# Check logs
kubectl logs deployment/backend
kubectl logs deployment/frontend
kubectl logs mongo-0

# Connect to MongoDB
kubectl exec -it mongo-0 -- mongosh

# Check Replica Set status
kubectl exec -it mongo-0 -- mongosh --eval "rs.status()"

# Get application URL
kubectl get ingress amazona-ingress

# Check Terraform state
aws s3 ls s3://amazona-terraform-state-608645726975/dev/
```

---

## 🗑️ Teardown

```bash
# 1. Delete Ingress first (removes ALB)
kubectl delete ingress amazona-ingress
sleep 60

# 2. Destroy all infrastructure
cd terraform
terraform destroy -auto-approve
```

> ⚠️ **Cost Warning:** EKS Control Plane costs ~$0.10/hour. Always destroy when not in use.

---

## 🔐 Security

- MongoDB has **no external port** exposed
- All services use **ClusterIP** (internal only)
- Only ALB is internet-facing
- **IRSA** ensures least-privilege access for AWS services
- Secrets stored as **Kubernetes Secrets** (not in code)
- `.env` file excluded from Git via `.gitignore`

---

## 👥 Team

| Role | Responsibility |
|------|---------------|
| DevOps Engineer 1 | Docker, docker-compose |
| DevOps Engineer 2 | Terraform, Kubernetes, EKS |

---

<div align="center">

**DEPI DevOps Graduation Project — 2026**

</div>
