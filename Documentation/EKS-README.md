# ☸️ Amazona — Kubernetes on AWS EKS

<div align="center">

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![AWS EKS](https://img.shields.io/badge/AWS_EKS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)

**Full deployment of the Amazona application on AWS EKS**

</div>

---

## 📋 Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [File Structure](#-file-structure)
- [Deployment Steps](#-deployment-steps)
- [File Explanations](#-file-explanations)
- [Useful Commands](#-useful-commands)
- [Cleanup / Teardown](#-cleanup--teardown)
- [Important Notes](#-important-notes)

---

## 🌟 Overview

These Kubernetes manifests deploy the Amazona application on AWS EKS:

```
User → AWS ALB → Ingress → Frontend (React) + Backend (Node.js) → MongoDB
```

---

## 🏗️ Architecture

![Kubernetes Architecture](Documentation/diagrams/K8s-diagram.png)
```
┌────────────────────────────────────────────────────┐
│                AWS EKS Cluster                     │
│                                                    │
│  Frontend Deployment (2 pods)                      │
│  ┌──────────┐  ┌──────────┐                        │
│  │ React +  │  │ React +  │ ← Frontend Service     │
│  │  Nginx   │  │  Nginx   │          ▲             │
│  └──────────┘  └──────────┘          │             │
│                                   Ingress          │
│  Backend Deployment (2 pods)         │             │
│  ┌──────────┐  ┌──────────┐          │             │
│  │ Node.js  │  │ Node.js  │ ← Backend Service      │
│  └────┬─────┘  └────┬─────┘          │             │
│       │             │            AWS ALB            │
│  MongoDB StatefulSet (3 pods)        │             │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ │             │
│  │ mongo-0 │ │ mongo-1 │ │ mongo-2 │ │             │
│  │PRIMARY  │ │SECONDARY│ │SECONDARY│ │             │
│  └────┬────┘ └────┬────┘ └────┬────┘ │             │
│      PVC         PVC         PVC      │             │
│    EBS gp2     EBS gp2     EBS gp2    │             │
└────────────────────────────────────────────────────┘
                                        │
                                      User
```

---

## 📁 File Structure

```
k8s/
├── backend-deployment.yaml     # Backend API pods (2 replicas)
├── backend-service.yaml        # Backend ClusterIP Service
├── frontend-deployment.yaml    # Frontend React pods (2 replicas)
├── frontend-service.yaml       # Frontend ClusterIP Service
├── mongo-statefulset.yaml      # MongoDB StatefulSet (3 replicas)
├── mongo-service.yaml          # MongoDB Headless + ClusterIP
├── ingress.yaml                # ALB Ingress (traffic routing)
├── secrets.yaml                # MongoDB URL + JWT Secret
└── hpa.yaml                    # Horizontal Pod Autoscaler
```

---

## 🚀 Deployment Steps

### Step 1: Provision the Infrastructure
```bash
cd terraform
terraform apply -auto-approve
```
⏳ Takes **15-20 minutes**

### Step 2: Deploy the Application
```bash
cd ..
./deploy.sh
```
⏳ Takes **5-10 minutes**

The script automatically:
- ✅ Connects kubectl to the EKS cluster
- ✅ Pushes images to ECR
- ✅ Applies all the manifests
- ✅ Waits for MongoDB to be ready
- ✅ Initializes the Replica Set
- ✅ Displays the application URL

### Step 3: Verification
```bash
kubectl get ingress amazona-ingress
curl -s http://<ALB-URL>/api/health
# Result: {"status":"healthy"}
```

---

## 📄 File Explanations

### 🔧 backend-deployment.yaml
Deploys two replicas of the Backend API on port 5000.

| Setting | Value | Reason |
|---------|--------|-------|
| replicas | 2 | High Availability |
| imagePullPolicy | Always | Latest image from ECR |
| readinessProbe | /api/health | Ready before receiving traffic |
| livenessProbe | /api/health | Restarts if it goes down |

---

### 🎨 frontend-deployment.yaml
Deploys two replicas of the Frontend (React + Nginx) on port 80.

---

### 🍃 mongo-statefulset.yaml
Deploys 3 replicas of MongoDB as a Replica Set.

**Why StatefulSet instead of Deployment?**

| Feature | StatefulSet ✅ | Deployment ❌ |
|--------|--------------|--------------|
| Stable name | mongo-0, mongo-1, mongo-2 | Random |
| Stable storage | PVC per pod | Deleted with the pod |
| Startup order | Sequential | Random |

```yaml
storageClassName: gp2    # AWS EBS for each pod
storage: 2Gi
```

---

### 🔗 mongo-service.yaml
There are two services:

**mongo-headless** → Stable DNS for each pod:
```
mongo-0.mongo-headless.default.svc.cluster.local:27017
mongo-1.mongo-headless.default.svc.cluster.local:27017
mongo-2.mongo-headless.default.svc.cluster.local:27017
```

**mongo** → ClusterIP for general access to MongoDB.

---

### 🌐 ingress.yaml
```
User → ALB → /api/* → Backend
           → /*     → Frontend
```

---

### 🔐 secrets.yaml
```yaml
MONGODB_URL: "mongodb://mongo-0.mongo-headless.default.svc.cluster.local:27017,..."
JWT_SECRET: "your-secret-key"
```

> ⚠️ **Very important:** the full DNS hostname is required:
> ```
> ✅ mongo-0.mongo-headless.default.svc.cluster.local:27017
> ❌ mongo-0.mongo-headless:27017
> ```

---

### 📊 hpa.yaml
```yaml
minReplicas: 1
maxReplicas: 5
targetCPU: 70%    # If CPU increases → adds pods
```

---

## 🛠️ Useful Commands

```bash
# Monitor pods
kubectl get pods
kubectl get pods -w

# Logs
kubectl logs deployment/backend
kubectl logs mongo-0

# MongoDB Replica Set
kubectl exec -it mongo-0 -- mongosh --eval \
  "rs.status().members.map(m => ({name: m.name, state: m.stateStr}))"

# Application URL
kubectl get ingress amazona-ingress

# PVCs
kubectl get pvc
```

---

## 🗑️ Cleanup / Teardown

```bash
# Delete the Ingress first (this removes the ALB)
kubectl delete ingress amazona-ingress
sleep 60

# If any Security Groups remain
aws ec2 delete-security-group --group-id <SG-ID>

# Destroy the infrastructure
cd terraform && terraform destroy -auto-approve
```

---

## ⚠️ Important Notes

**1. MongoDB Full Hostname**
```
✅ mongo-0.mongo-headless.default.svc.cluster.local:27017
❌ mongo-0.mongo-headless:27017
```

**2. Node Size**
```
t3.medium → For the application + Monitoring ✅
t3.small  → For the application only (max 11 pods)
```

**3. Cost**
> Always run `terraform destroy` when you're done!

---

<div align="center">

**DEPI DevOps Graduation Project — EKS Documentation — 2026**

</div>
