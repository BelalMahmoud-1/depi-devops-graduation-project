# ☸️ Amazona — Kubernetes on AWS EKS

<div align="center">

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![AWS EKS](https://img.shields.io/badge/AWS_EKS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)

**نشر تطبيق Amazona الكامل على AWS EKS**

</div>

---

## 📋 المحتويات

- [نظرة عامة](#-نظرة-عامة)
- [Architecture](#-architecture)
- [هيكل الملفات](#-هيكل-الملفات)
- [خطوات التشغيل](#-خطوات-التشغيل)
- [شرح كل ملف](#-شرح-كل-ملف)
- [أوامر مفيدة](#-أوامر-مفيدة)
- [حذف كل حاجة](#-حذف-كل-حاجة)
- [ملاحظات مهمة](#-ملاحظات-مهمة)

---

## 🌟 نظرة عامة

الـ Kubernetes manifests دي بتنشر تطبيق Amazona على AWS EKS:

```
User → AWS ALB → Ingress → Frontend (React) + Backend (Node.js) → MongoDB
```

---

## 🏗️ Architecture

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

## 📁 هيكل الملفات

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

## 🚀 خطوات التشغيل

### خطوة ١: إنشاء البنية التحتية
```bash
cd terraform
terraform apply -auto-approve
```
⏳ ينتظر **15-20 دقيقة**

### خطوة ٢: نشر التطبيق
```bash
cd ..
./deploy.sh
```
⏳ ينتظر **5-10 دقايق**

الـ script بيعمل أوتوماتيك:
- ✅ يوصّل kubectl بالـ EKS
- ✅ يرفع images على ECR
- ✅ يطبق كل الـ manifests
- ✅ ينتظر MongoDB تكون جاهزة
- ✅ يعمل init للـ Replica Set
- ✅ يعرض رابط التطبيق

### خطوة ٣: التحقق
```bash
kubectl get ingress amazona-ingress
curl -s http://<ALB-URL>/api/health
# النتيجة: {"status":"healthy"}
```

---

## 📄 شرح كل ملف

### 🔧 backend-deployment.yaml
ينشر نسختين من Backend API على port 5000.

| الإعداد | القيمة | السبب |
|---------|--------|-------|
| replicas | 2 | High Availability |
| imagePullPolicy | Always | أحدث image من ECR |
| readinessProbe | /api/health | جاهز قبل الـ traffic |
| livenessProbe | /api/health | يعيد التشغيل لو وقف |

---

### 🎨 frontend-deployment.yaml
ينشر نسختين من Frontend (React + Nginx) على port 80.

---

### 🍃 mongo-statefulset.yaml
ينشر 3 نسخ من MongoDB كـ Replica Set.

**ليه StatefulSet وليس Deployment؟**

| الميزة | StatefulSet ✅ | Deployment ❌ |
|--------|--------------|--------------|
| اسم ثابت | mongo-0, mongo-1, mongo-2 | عشوائي |
| storage ثابت | PVC لكل pod | يُحذف مع الـ pod |
| ترتيب التشغيل | بالترتيب | عشوائي |

```yaml
storageClassName: gp2    # AWS EBS لكل pod
storage: 2Gi
```

---

### 🔗 mongo-service.yaml
فيه خدمتين:

**mongo-headless** → DNS ثابت لكل pod:
```
mongo-0.mongo-headless.default.svc.cluster.local:27017
mongo-1.mongo-headless.default.svc.cluster.local:27017
mongo-2.mongo-headless.default.svc.cluster.local:27017
```

**mongo** → ClusterIP للوصول العام للـ MongoDB.

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

> ⚠️ **مهم جداً:** لازم Full DNS hostname:
> ```
> ✅ mongo-0.mongo-headless.default.svc.cluster.local:27017
> ❌ mongo-0.mongo-headless:27017
> ```

---

### 📊 hpa.yaml
```yaml
minReplicas: 1
maxReplicas: 5
targetCPU: 70%    # لو CPU زاد → يضيف pods
```

---

## 🛠️ أوامر مفيدة

```bash
# مراقبة الـ pods
kubectl get pods
kubectl get pods -w

# logs
kubectl logs deployment/backend
kubectl logs mongo-0

# MongoDB Replica Set
kubectl exec -it mongo-0 -- mongosh --eval \
  "rs.status().members.map(m => ({name: m.name, state: m.stateStr}))"

# رابط التطبيق
kubectl get ingress amazona-ingress

# PVCs
kubectl get pvc
```

---

## 🗑️ حذف كل حاجة

```bash
# احذف الـ Ingress الأول (يمسح ALB)
kubectl delete ingress amazona-ingress
sleep 60

# لو في Security Groups متبقية
aws ec2 delete-security-group --group-id <SG-ID>

# احذف البنية التحتية
cd terraform && terraform destroy -auto-approve
```

---

## ⚠️ ملاحظات مهمة

**١. MongoDB Full Hostname**
```
✅ mongo-0.mongo-headless.default.svc.cluster.local:27017
❌ mongo-0.mongo-headless:27017
```

**٢. Node Size**
```
t3.medium → للتطبيق + Monitoring ✅
t3.small  → للتطبيق بس (max 11 pods)
```

**٣. تكلفة**
> دايماً عمل `terraform destroy` لما تخلص!

---

<div align="center">

**DEPI DevOps Graduation Project — EKS Documentation — 2026**

</div>
