# 📊 Amazona — Monitoring Stack

<div align="center">

![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Alertmanager](https://img.shields.io/badge/Alertmanager-FF6600?style=for-the-badge&logo=prometheus&logoColor=white)
![Slack](https://img.shields.io/badge/Slack-4A154B?style=for-the-badge&logo=slack&logoColor=white)

**مراقبة تطبيق Amazona على AWS EKS باستخدام Prometheus + Grafana**

</div>

---

## 📋 المحتويات

- [نظرة عامة](#-نظرة-عامة)
- [علاقة الـ Monitoring بالـ EKS](#-علاقة-الـ-monitoring-بالـ-eks)
- [هيكل الملفات](#-هيكل-الملفات)
- [شرح كل أداة](#-شرح-كل-أداة)
- [خطوات التثبيت](#-خطوات-التثبيت)
- [الوصول لـ Grafana](#-الوصول-لـ-grafana)
- [Dashboards المتاحة](#-dashboards-المتاحة)
- [Alerts على Slack](#-alerts-على-slack)
- [أوامر مفيدة](#-أوامر-مفيدة)
- [ملاحظات مهمة](#-ملاحظات-مهمة)

---

## 🌟 نظرة عامة

الـ Monitoring Stack بتراقب كل حاجة بتحصل في الـ EKS cluster:

```
EKS Cluster (pods, nodes, resources)
         ↓ metrics
      Prometheus
         ↓ بيبعت data
       Grafana          → Dashboards (CPU, Memory, Requests)
         ↓ alerts
     Alertmanager       → Slack Notifications
```

---

## 🔗 علاقة الـ Monitoring بالـ EKS

الـ Monitoring مش منفصل عن الـ EKS — هو بيشتغل **جوّاه**:

```
┌──────────────────────────────────────────────────────────┐
│                    AWS EKS Cluster                       │
│                                                          │
│  ┌─────────────────────┐  ┌──────────────────────────┐  │
│  │  default namespace  │  │  monitoring namespace    │  │
│  │                     │  │                          │  │
│  │  ✅ Frontend pods   │  │  📊 Prometheus           │  │
│  │  ✅ Backend pods    │  │  📈 Grafana              │  │
│  │  ✅ MongoDB pods    │  │  🔔 Alertmanager         │  │
│  │                     │  │  📦 kube-state-metrics   │  │
│  └─────────────────────┘  └──────────────────────────┘  │
│            ↑                          │                  │
│            └──── Prometheus يراقب ────┘                  │
└──────────────────────────────────────────────────────────┘
```

**يعني:**
- Prometheus **جوّا الـ EKS** بيجمع metrics من كل الـ pods والـ nodes
- Grafana **جوّا الـ EKS** بيعرض الـ metrics على شكل dashboards
- Alertmanager **جوّا الـ EKS** بيبعت alerts لـ Slack لو في مشكلة

---

## 📁 هيكل الملفات

```
monitoring/
├── values-monitoring.yaml      # إعدادات kube-prometheus-stack
├── alertmanager-config.yaml    # إعدادات الـ alerts
├── prometheus-rules.yaml       # قواعد الـ alerts المخصصة
├── slack-secret.yaml           # Slack webhook secret
└── grafana-ingress.yaml        # ALB Ingress لـ Grafana ✨
```

---

## 🛠️ شرح كل أداة

### 📊 Prometheus
**هو إيه؟**
قاعدة بيانات للـ time-series metrics — بيجمع أرقام من كل حاجة في الـ cluster كل 15 ثانية.

**بيجمع إيه؟**
- CPU usage لكل pod
- Memory usage لكل pod
- Network traffic
- عدد الـ requests على الـ API
- حالة الـ nodes

**إزاي بيشتغل؟**
```
Prometheus → يسأل كل pod كل 15 ثانية (scraping)
           → يحفظ الأرقام في قاعدة بياناته
           → Grafana يسأله عن الأرقام ويعرضها
```

---

### 📈 Grafana
**هو إيه؟**
أداة لعرض الـ metrics على شكل graphs و dashboards.

**بيشتغل إزاي مع EKS؟**
```
Grafana → يتصل بـ Prometheus (data source)
        → يجيب الأرقام
        → يعرضها في dashboards جميلة
```

**الوصول:**
```
URL: http://<Grafana-ALB-URL>
Username: admin
Password: (بيظهر في نهاية install-monitoring.sh)
```

---

### 🔔 Alertmanager
**هو إيه؟**
نظام الإنذار — لو في مشكلة في الـ cluster، بيبعت message على Slack.

**أمثلة على الـ alerts:**
- Pod بيعمل CrashLoopBackOff
- Memory زادت عن 80%
- CPU زادت عن 90%
- Node وقعت

---

### 📦 kube-state-metrics
بيحول حالة الـ Kubernetes objects (pods, deployments, nodes) لـ metrics يقدر Prometheus يجمعها.

---

## 🚀 خطوات التثبيت

> ⚠️ **تأكد إن الـ EKS شغال الأول** قبل تثبيت الـ Monitoring

```bash
# تأكد إن الـ EKS شغال
kubectl get nodes

# شغّل الـ Monitoring
./install-monitoring.sh
```

**الـ script بيعمل:**
1. يضيف Prometheus Helm repo
2. ينشئ `monitoring` namespace
3. ينشئ Slack secret
4. يثبت kube-prometheus-stack
5. ينتظر الـ operator يكون جاهز
6. يطبق Alertmanager config
7. يطبق Prometheus rules
8. ينشئ Grafana Ingress ✨
9. يعرض رابط Grafana + Password

⏳ ينتظر **5-10 دقايق**

---

## 🌐 الوصول لـ Grafana

```bash
# رابط Grafana
kubectl get ingress grafana-ingress -n monitoring
```

افتح في المتصفح:
```
http://<Grafana-ALB-URL>
Username: admin
Password: (من نتيجة install-monitoring.sh)
```

### ليه استخدمنا Ingress مش LoadBalancer Service؟

لو استخدمنا `kubectl patch svc` لتحويل الـ Grafana service لـ LoadBalancer:
- ❌ AWS بيعمل **Classic Load Balancer** قديم
- ❌ بيعمل Security Group منفصل
- ❌ لما تعمل `terraform destroy` الـ VPC مش بيتمسح بسبب الـ SG

بدلوه عملنا **Ingress** يستخدم الـ ALB الموجود:
- ✅ نفس الـ ALB بتاع التطبيق
- ✅ مش بيعمل resources جديدة
- ✅ `terraform destroy` بيشتغل بدون مشاكل

---

## 📊 Dashboards المتاحة

| Dashboard | الوظيفة |
|-----------|---------|
| Kubernetes / Compute Resources / Cluster | CPU و Memory للكلاستر كله |
| Kubernetes / Compute Resources / Namespace (Pods) | مراقبة pods بالـ namespace |
| Kubernetes / Compute Resources / Node (Pods) | مراقبة كل node |
| Kubernetes / Persistent Volumes | مراقبة MongoDB EBS storage |
| Alertmanager / Overview | مراقبة الـ alerts |
| Prometheus / Overview | مراقبة Prometheus نفسه |

---

## 🔔 Alerts على Slack

### إعداد الـ Slack Webhook
```yaml
# monitoring/slack-secret.yaml
stringData:
  slack-webhook-url: "YOUR_SLACK_WEBHOOK_URL"
```

### أنواع الـ Alerts
| Alert | السبب | الخطورة |
|-------|-------|---------|
| PodCrashLooping | Pod بيعمل restart كتير | Critical |
| HighMemoryUsage | Memory > 80% | Warning |
| HighCPUUsage | CPU > 90% | Warning |
| NodeNotReady | Node وقعت | Critical |

---

## 🛠️ أوامر مفيدة

```bash
# مراقبة الـ monitoring pods
kubectl get pods -n monitoring

# logs الـ Prometheus
kubectl logs -n monitoring prometheus-kube-prometheus-stack-prometheus-0

# logs الـ Grafana
kubectl logs -n monitoring deployment/kube-prometheus-stack-grafana

# logs الـ Alertmanager
kubectl logs -n monitoring alertmanager-kube-prometheus-stack-alertmanager-0

# رابط Grafana
kubectl get ingress grafana-ingress -n monitoring

# password Grafana
kubectl get secret kube-prometheus-stack-grafana \
  -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 -d
```

---

## ⚠️ ملاحظات مهمة

### ١. Node Size
الـ Monitoring محتاج pods كتير:

| Instance | Max Pods | مناسب |
|----------|----------|-------|
| t3.small | 11 pods | ❌ مش كفاية |
| t3.medium | 17 pods | ✅ كافي |

**استخدم دايماً `t3.medium`** لما تشغّل الـ Monitoring.

### ٢. Grafana Ingress مش LoadBalancer
```bash
# ✅ صح - Ingress
kubectl apply -f monitoring/grafana-ingress.yaml

# ❌ غلط - بيعمل Classic LB
kubectl patch svc kube-prometheus-stack-grafana -n monitoring -p '{"spec":{"type":"LoadBalancer"}}'
```

### ٣. ترتيب التشغيل
```
terraform apply → deploy.sh → install-monitoring.sh
```
الـ Monitoring لازم يتثبت بعد ما التطبيق يكون شغال.

---

<div align="center">

**DEPI DevOps Graduation Project — Monitoring Documentation — 2026**

</div>
