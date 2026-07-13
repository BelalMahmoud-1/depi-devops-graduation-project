#!/bin/bash
set -e

CLUSTER_NAME="amazona-dev-cluster"
REGION="us-east-1"
ACCOUNT_ID="608645726975"
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================"
echo "  Amazona Deployment Script"
echo "======================================"

echo ""
echo "=== 1. Update kubeconfig ==="
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

echo ""
echo "=== 2. Login to ECR ==="
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL

echo ""
echo "=== 3. Push images to ECR ==="
docker tag depi-devops-graduation-project-backend:latest $ECR_URL/amazona-backend:latest
docker push $ECR_URL/amazona-backend:latest
docker tag depi-devops-graduation-project-frontend:latest $ECR_URL/amazona-frontend:latest
docker push $ECR_URL/amazona-frontend:latest

echo ""
echo "=== 4. Create K8s secrets ==="
kubectl create secret generic backend-secrets \
  --from-literal=MONGODB_URL="mongodb://mongo-0.mongo-headless.default.svc.cluster.local:27017,mongo-1.mongo-headless.default.svc.cluster.local:27017,mongo-2.mongo-headless.default.svc.cluster.local:27017/amazona?replicaSet=rs0" \
  --from-literal=JWT_SECRET="amazona-super-secret-jwt-key-2024" \
  --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "=== 5. Apply K8s manifests ==="
kubectl apply -f $SCRIPT_DIR/k8s/mongo-statefulset.yaml
kubectl apply -f $SCRIPT_DIR/k8s/mongo-service.yaml
kubectl apply -f $SCRIPT_DIR/k8s/backend-deployment.yaml
kubectl apply -f $SCRIPT_DIR/k8s/backend-service.yaml
kubectl apply -f $SCRIPT_DIR/k8s/frontend-deployment.yaml
kubectl apply -f $SCRIPT_DIR/k8s/frontend-service.yaml
kubectl apply -f $SCRIPT_DIR/k8s/ingress.yaml

echo ""
echo "=== 6. Waiting for MongoDB ==="
kubectl rollout status statefulset/mongo --timeout=300s

echo ""
echo "=== 7. Init MongoDB Replica Set ==="
sleep 10
kubectl exec -it mongo-0 -- mongosh --eval "
try {
  rs.initiate({
    _id: 'rs0',
    members: [
      { _id: 0, host: 'mongo-0.mongo-headless.default.svc.cluster.local:27017' },
      { _id: 1, host: 'mongo-1.mongo-headless.default.svc.cluster.local:27017' },
      { _id: 2, host: 'mongo-2.mongo-headless.default.svc.cluster.local:27017' }
    ]
  });
} catch(e) {
  if (e.code === 23) print('Replica set already initialized');
  else throw e;
}
" || true

echo ""
echo "=== 8. Restart backend ==="
kubectl rollout restart deployment/backend
kubectl rollout status deployment/backend --timeout=120s

echo ""
echo "=== Done! ==="
sleep 30
kubectl get ingress amazona-ingress
