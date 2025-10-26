#!/bin/bash
set -e

# ENV variables
ARGO_CD="argocd"
KEYCLOAK="keycloak"

# Set up
minikube start
  
# Create the Argo CD namespace
kubectl create namespace "$ARGO_CD"
  
# Install Argo CD
kubectl apply -n "$ARGO_CD" -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  
# Wait for Argo CD to be ready
echo "Waiting for Argo CD pods to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n "$ARGO_CD"
  
# Apply Application manifest
echo "Applying Argo CD Application..."
kubectl apply -f https://raw.githubusercontent.com/tobbeee/stekt-flesk/main/app.yml

# Wait for Argo CD to create the Keycloak namespace
echo "⏳ Waiting for namespace $KEYCLOAK to be created by Argo CD..."
# Wait until the namespace appears (max 5 min)
for i in {1..15}; do
  if kubectl get ns "$KEYCLOAK" &>/dev/null; then
    echo "✅ Namespace $KEYCLOAK exists."
    break
  fi
  echo "⏳ Namespace $KEYCLOAK not found yet... retrying in 20s"
  sleep 20
  if [ "$i" -eq 15 ]; then
    echo "❌ Timed out waiting for namespace $KEYCLOAK to be created."
    exit 1
  fi
done

echo "✅ Argo CD and keycloak are up!"

# Get and print admin password for Argo CD
echo
echo "🔑 Fetching Argo CD admin password:"
ADMIN_ARGO_PWD=$(kubectl -n "$ARGO_CD" get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)
echo "Username: admin"
echo "Password: $ADMIN_ARGO_PWD"
echo

# Get and print admin password for keycloak
echo
echo "🔑 Fetching Keycloak admin password:"
ADMIN_KEYCLOAK_PWD=$(kubectl -n "$KEYCLOAK" get secret "$KEYCLOAK" \
  -o jsonpath="{.data.admin-password}" | base64 -d)
echo "Username: user"
echo "Password: $ADMIN_KEYCLOAK_PWD"
echo

# Start port forwarding in the background for Argo CD
echo "🌐 Starting port-forward to Argo CD UI (https://localhost:8081)"
kubectl port-forward svc/argocd-server -n "$ARGO_CD" 8081:443 >/dev/null 2>&1 &
PORT_FORWARD_ARGO_PID=$!

# Start port forwarding in the background for Keycloak
echo "🌐 Starting port-forward to Keycloak (http://localhost:8082)"
kubectl port-forward svc/"$KEYCLOAK" -n "$KEYCLOAK" 8082:80 >/dev/null 2>&1 &
PORT_FORWARD_KEYCLOAK_PID=$!

# Final messages
echo "✅ Port-forward running for Argo CD in background (PID: $PORT_FORWARD_ARGO_PID)"
echo "✅ Port-forward running for keycloak in background (PID: $PORT_FORWARD_KEYCLOAK_PID)"
echo "💡 Access the Argo CD UI at: https://localhost:8081"
echo "💡 Access the Keycloak UI at: http://localhost:8082"
echo "💡 Stop port-forward for Argo CD with: kill $PORT_FORWARD_ARGO_PID"
echo "💡 Stop port-forward for keycloak with: kill $PORT_FORWARD_KEYCLOAK_PID"
