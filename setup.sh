#!/bin/bash
set -e
  
# Delete old instance of minikube and start it
minikube delete
minikube start
  
# Create the Argo CD namespace
kubectl create namespace argocd
  
# Install or Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  
# Wait for Argo CD to be ready
echo "Waiting for Argo CD pods to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
  
# Apply Application manifest
echo "Applying Argo CD Application..."
kubectl apply -f https://raw.githubusercontent.com/tobbeee/stekt-flesk/main/app.yml

echo "✅ Argo CD and stektflesk app are up!"

# Get and print admin password
echo
echo "🔑 Fetching Argo CD admin password:"
ADMIN_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)
echo "Username: admin"
echo "Password: $ADMIN_PWD"
echo

# Start port forwarding in the background
echo "🌐 Starting port-forward to Argo CD UI (https://localhost:8081)"
kubectl port-forward svc/argocd-server -n argocd 8081:443 >/dev/null 2>&1 &
PORT_FORWARD_PID=$!

echo "✅ Port-forward running in background (PID: $PORT_FORWARD_PID)"
echo "💡 Access the Argo CD UI at: https://localhost:8081"
echo "💡 Stop port-forward with: kill $PORT_FORWARD_PID"
