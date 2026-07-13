#!/bin/bash

set -e

echo "=========================================="
echo "      Amazona Monitoring Setup"
echo "=========================================="
echo

echo "========== [1/8] Updating Helm Repository =========="
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update
echo

echo "========== [2/8] Creating Monitoring Namespace =========="
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
echo

echo "========== [3/8] Creating Slack Secret =========="
kubectl apply -f monitoring/slack-secret.yaml
echo

echo "========== [4/8] Installing kube-prometheus-stack =========="
helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f monitoring/values-monitoring.yaml
echo

echo "========== [5/8] Waiting for Prometheus Operator =========="
kubectl rollout status deployment/kube-prometheus-stack-operator \
  -n monitoring \
  --timeout=10m
echo

echo "========== [6/8] Applying Alertmanager Config =========="
kubectl apply -f monitoring/alertmanager-config.yaml
echo

echo "========== [7/8] Applying Prometheus Rules =========="
kubectl apply -f monitoring/prometheus-rules.yaml
echo

echo "========== [8/8] Monitoring Status =========="
kubectl get pods -n monitoring
echo

echo "=========================================="
echo " Monitoring Installation Completed "
echo "=========================================="
echo
echo "Grafana Username: admin"
echo
echo "Grafana Password:"
kubectl get secret kube-prometheus-stack-grafana \
  -n monitoring \
  -o jsonpath="{.data.admin-password}" | base64 -d
echo

echo "========== [9/9] Creating Grafana Ingress =========="
kubectl apply -f monitoring/grafana-ingress.yaml
echo "Waiting for Grafana URL (60s)..."
sleep 60
GRAFANA_URL=$(kubectl get ingress grafana-ingress -n monitoring -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo ""
echo "=========================================="
echo " Grafana URL: http://$GRAFANA_URL"
echo "=========================================="
