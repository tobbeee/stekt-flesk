#!/bin/bash
set -e
  
# Start Minikube if not already running
minikube start
  
# Create the Argo CD namespace if it doesn't exist
kubectl get ns argocd >/dev/null 2>&1 || kubectl create namespace argocd
  
# Install or upgrade Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  
# Wait for Argo CD to be ready
echo "Waiting for Argo CD pods to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
  
# Apply Application manifest
echo "Applying Argo CD Application..."
kubectl apply -f https://raw.githubusercontent.com/tobbeee/stekt-flesk/main/app.yml

echo "✅ Argo CD and stektflesk app are up!"