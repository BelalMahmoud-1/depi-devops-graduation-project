# 📊 Amazona — Monitoring Stack

<div align="center">

![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white)
![Alertmanager](https://img.shields.io/badge/Alertmanager-FF6600?style=for-the-badge&logo=prometheus&logoColor=white)
![Slack](https://img.shields.io/badge/Slack-4A154B?style=for-the-badge&logo=slack&logoColor=white)

**Monitoring the Amazona application on AWS EKS using Prometheus + Grafana**

</div>

---

## 📋 Contents

- [Overview](#-overview)
- [How Monitoring Relates to EKS](#-how-monitoring-relates-to-eks)
- [File Structure](#-file-structure)
- [Tool Explanations](#-tool-explanations)
- [Installation Steps](#-installation-steps)
- [Accessing Grafana](#-accessing-grafana)
- [Available Dashboards](#-available-dashboards)
- [Slack Alerts](#-slack-alerts)
- [Useful Commands](#-useful-commands)
- [Important Notes](#-important-notes)

---

## 🌟 Overview

The Monitoring Stack watches everything happening in the EKS cluster:

```
EKS Cluster (pods, nodes, resources)
         ↓ metrics
      Prometheus
         ↓ sends data
       Grafana          → Dashboards (CPU, Memory, Requests)
         ↓ alerts
     Alertmanager       → Slack Notifications
```

---

## 🔗 How Monitoring Relates to EKS

Monitoring isn't separate from EKS — it runs **inside it**:

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
│            └──── Prometheus monitors ──┘                  │
└──────────────────────────────────────────────────────────┘
```

**In other words:**
- Prometheus **inside EKS** collects metrics from all the pods and nodes
- Grafana **inside EKS** displays the metrics as dashboards
- Alertmanager **inside EKS** sends alerts to Slack if there's a problem

---

## 📁 File Structure

```
monitoring/
├── values-monitoring.yaml      # kube-prometheus-stack configuration
├── alertmanager-config.yaml    # Alert configuration
├── prometheus-rules.yaml       # Custom alert rules
├── slack-secret.yaml           # Slack webhook secret
└── grafana-ingress.yaml        # ALB Ingress for Grafana ✨
```

---

## 🛠️ Tool Explanations

### 📊 Prometheus
**What is it?**
A time-series metrics database — it collects numbers from everything in the cluster every 15 seconds.

**What does it collect?**
- CPU usage per pod
- Memory usage per pod
- Network traffic
- Number of requests on the API
- Node status

**How does it work?**
```
Prometheus → queries every pod every 15 seconds (scraping)
           → stores the numbers in its database
           → Grafana queries it for the numbers and displays them
```

---

### 📈 Grafana
**What is it?**
A tool for displaying metrics as graphs and dashboards.

**How does it work with EKS?**
```
Grafana → connects to Prometheus (data source)
        → fetches the numbers
        → displays them in nice dashboards
```

**Access:**
```
URL: http://<Grafana-ALB-URL>
Username: admin
Password: (shown at the end of install-monitoring.sh)
```

---

### 🔔 Alertmanager
**What is it?**
The alerting system — if there's a problem in the cluster, it sends a message to Slack.

**Examples of alerts:**
- A pod is in CrashLoopBackOff
- Memory exceeded 80%
- CPU exceeded 90%
- A node went down

---

### 📦 kube-state-metrics
Converts the state of Kubernetes objects (pods, deployments, nodes) into metrics that Prometheus can collect.

---

## 🚀 Installation Steps

> ⚠️ **Make sure EKS is running first** before installing Monitoring

```bash
# Confirm EKS is running
kubectl get nodes

# Run Monitoring
./install-monitoring.sh
```

**The script does:**
1. Adds the Prometheus Helm repo
2. Creates the `monitoring` namespace
3. Creates the Slack secret
4. Installs kube-prometheus-stack
5. Waits for the operator to be ready
6. Applies the Alertmanager config
7. Applies the Prometheus rules
8. Creates the Grafana Ingress ✨
9. Displays the Grafana URL + Password

⏳ Takes **5-10 minutes**

---

## 🌐 Accessing Grafana

```bash
# Grafana URL
kubectl get ingress grafana-ingress -n monitoring
```

Open in your browser:
```
http://<Grafana-ALB-URL>
Username: admin
Password: (from the install-monitoring.sh output)
```

### Why did we use an Ingress instead of a LoadBalancer Service?

If we used `kubectl patch svc` to convert the Grafana service to a LoadBalancer:
- ❌ AWS creates an old-style **Classic Load Balancer**
- ❌ It creates a separate Security Group
- ❌ When you run `terraform destroy`, the VPC won't be deleted because of the SG

Instead, we created an **Ingress** that uses the existing ALB:
- ✅ Same ALB as the application
- ✅ Doesn't create new resources
- ✅ `terraform destroy` runs without issues

---

## 📊 Available Dashboards

| Dashboard | Purpose |
|-----------|---------|
| Kubernetes / Compute Resources / Cluster | CPU and Memory for the whole cluster |
| Kubernetes / Compute Resources / Namespace (Pods) | Monitor pods by namespace |
| Kubernetes / Compute Resources / Node (Pods) | Monitor each node |
| Kubernetes / Persistent Volumes | Monitor MongoDB EBS storage |
| Alertmanager / Overview | Monitor alerts |
| Prometheus / Overview | Monitor Prometheus itself |

---

## 🔔 Slack Alerts

### Setting Up the Slack Webhook
```yaml
# monitoring/slack-secret.yaml
stringData:
  slack-webhook-url: "YOUR_SLACK_WEBHOOK_URL"
```

### Types of Alerts
| Alert | Reason | Severity |
|-------|-------|---------|
| PodCrashLooping | Pod restarting frequently | Critical |
| HighMemoryUsage | Memory > 80% | Warning |
| HighCPUUsage | CPU > 90% | Warning |
| NodeNotReady | A node went down | Critical |

---

## 🛠️ Useful Commands

```bash
# Monitor the monitoring pods
kubectl get pods -n monitoring

# Prometheus logs
kubectl logs -n monitoring prometheus-kube-prometheus-stack-prometheus-0

# Grafana logs
kubectl logs -n monitoring deployment/kube-prometheus-stack-grafana

# Alertmanager logs
kubectl logs -n monitoring alertmanager-kube-prometheus-stack-alertmanager-0

# Grafana URL
kubectl get ingress grafana-ingress -n monitoring

# Grafana password
kubectl get secret kube-prometheus-stack-grafana \
  -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 -d
```

---

## ⚠️ Important Notes

### 1. Node Size
Monitoring needs a lot of pods:

| Instance | Max Pods | Suitable |
|----------|----------|-------|
| t3.small | 11 pods | ❌ Not enough |
| t3.medium | 17 pods | ✅ Enough |

**Always use `t3.medium`** when running Monitoring.

### 2. Grafana Ingress, not LoadBalancer
```bash
# ✅ Correct - Ingress
kubectl apply -f monitoring/grafana-ingress.yaml

# ❌ Wrong - creates a Classic LB
kubectl patch svc kube-prometheus-stack-grafana -n monitoring -p '{"spec":{"type":"LoadBalancer"}}'
```

### 3. Deployment Order
```
terraform apply → deploy.sh → install-monitoring.sh
```
Monitoring must be installed after the application is already running.

---

<div align="center">

**DEPI DevOps Graduation Project — Monitoring Documentation — 2026**

</div>
