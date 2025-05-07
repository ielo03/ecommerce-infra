#!/bin/bash
# Script to deploy the ecommerce platform to the UAT environment

set -e

# Set environment variables
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="us-west-2"
export VERSION="1.0.0"
export DB_HOST="ecommerce-uat-db.cluster-abcdefghijkl.us-west-2.rds.amazonaws.com"
export DB_USERNAME="admin"
export DB_PASSWORD="your-secure-password"
export JWT_SECRET="your-jwt-secret"

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Create namespace if it doesn't exist
kubectl create namespace ecommerce-uat --dry-run=client -o yaml | kubectl apply -f -

# Create secrets for each service
echo "Creating secrets for product-service..."
kubectl create secret generic product-service-secrets \
  --namespace ecommerce-uat \
  --from-literal=db_username=${DB_USERNAME} \
  --from-literal=db_password=${DB_PASSWORD} \
  --from-literal=jwt_secret=${JWT_SECRET} \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Creating secrets for order-service..."
kubectl create secret generic order-service-secrets \
  --namespace ecommerce-uat \
  --from-literal=db_username=${DB_USERNAME} \
  --from-literal=db_password=${DB_PASSWORD} \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Creating secrets for user-service..."
kubectl create secret generic user-service-secrets \
  --namespace ecommerce-uat \
  --from-literal=db_username=${DB_USERNAME} \
  --from-literal=db_password=${DB_PASSWORD} \
  --from-literal=jwt_secret=${JWT_SECRET} \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Creating secrets for api-gateway..."
kubectl create secret generic api-gateway-secrets \
  --namespace ecommerce-uat \
  --from-literal=jwt_secret=${JWT_SECRET} \
  --dry-run=client -o yaml | kubectl apply -f -

# Check if the required directories exist
echo "Checking if required directories exist..."
if [ ! -d "${REPO_ROOT}/kubernetes/overlays/uat/product-service" ]; then
  echo "Creating product-service directory..."
  mkdir -p "${REPO_ROOT}/kubernetes/overlays/uat/product-service"
fi

if [ ! -d "${REPO_ROOT}/kubernetes/overlays/uat/order-service" ]; then
  echo "Creating order-service directory..."
  mkdir -p "${REPO_ROOT}/kubernetes/overlays/uat/order-service"
fi

if [ ! -d "${REPO_ROOT}/kubernetes/overlays/uat/user-service" ]; then
  echo "Creating user-service directory..."
  mkdir -p "${REPO_ROOT}/kubernetes/overlays/uat/user-service"
fi

if [ ! -d "${REPO_ROOT}/kubernetes/overlays/uat/api-gateway" ]; then
  echo "Creating api-gateway directory..."
  mkdir -p "${REPO_ROOT}/kubernetes/overlays/uat/api-gateway"
fi

# Create kustomization files if they don't exist
echo "Creating kustomization files if they don't exist..."

# Create product-service kustomization file
if [ ! -f "${REPO_ROOT}/kubernetes/overlays/uat/product-service/kustomization.yaml" ]; then
  echo "Creating product-service kustomization file..."
  cat > "${REPO_ROOT}/kubernetes/overlays/uat/product-service/kustomization.yaml" << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ecommerce-uat

resources:
  - ../../../base/product-service

commonLabels:
  environment: uat

images:
  - name: ecommerce-uat/product-service
    newName: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecommerce-uat/product-service
    newTag: ${VERSION}

configMapGenerator:
  - name: product-service-config
    literals:
      - db_host=${DB_HOST}
      - db_port=3306
      - db_name=ecommerce_products
      - log_level=info
      - enable_inventory_check=true
      - enable_recommendations=false
      - enable_caching=true

patchesStrategicMerge:
  - deployment-patch.yaml
  - service-patch.yaml
EOF
fi

# Create order-service kustomization file
if [ ! -f "${REPO_ROOT}/kubernetes/overlays/uat/order-service/kustomization.yaml" ]; then
  echo "Creating order-service kustomization file..."
  cat > "${REPO_ROOT}/kubernetes/overlays/uat/order-service/kustomization.yaml" << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ecommerce-uat

resources:
  - ../../../base/order-service

commonLabels:
  environment: uat

images:
  - name: ecommerce-uat/order-service
    newName: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecommerce-uat/order-service
    newTag: ${VERSION}

configMapGenerator:
  - name: order-service-config
    literals:
      - db_host=${DB_HOST}
      - db_port=3306
      - db_name=ecommerce_orders
      - log_level=info

patchesStrategicMerge:
  - deployment-patch.yaml
  - service-patch.yaml
EOF
fi

# Create user-service kustomization file
if [ ! -f "${REPO_ROOT}/kubernetes/overlays/uat/user-service/kustomization.yaml" ]; then
  echo "Creating user-service kustomization file..."
  cat > "${REPO_ROOT}/kubernetes/overlays/uat/user-service/kustomization.yaml" << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ecommerce-uat

resources:
  - ../../../base/user-service

commonLabels:
  environment: uat

images:
  - name: ecommerce-uat/user-service
    newName: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecommerce-uat/user-service
    newTag: ${VERSION}

configMapGenerator:
  - name: user-service-config
    literals:
      - db_host=${DB_HOST}
      - db_port=3306
      - db_name=ecommerce_users
      - log_level=info

patchesStrategicMerge:
  - deployment-patch.yaml
  - service-patch.yaml
EOF
fi

# Create api-gateway kustomization file
if [ ! -f "${REPO_ROOT}/kubernetes/overlays/uat/api-gateway/kustomization.yaml" ]; then
  echo "Creating api-gateway kustomization file..."
  cat > "${REPO_ROOT}/kubernetes/overlays/uat/api-gateway/kustomization.yaml" << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: ecommerce-uat

resources:
  - ../../../base/api-gateway

commonLabels:
  environment: uat

images:
  - name: ecommerce-uat/api-gateway
    newName: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecommerce-uat/api-gateway
    newTag: ${VERSION}

configMapGenerator:
  - name: api-gateway-config
    literals:
      - product_service_url=http://product-service:8080
      - order_service_url=http://order-service:8080
      - user_service_url=http://user-service:8080
      - log_level=info

patchesStrategicMerge:
  - deployment-patch.yaml
  - service-patch.yaml
EOF
fi

# Create deployment patch files if they don't exist
echo "Creating deployment patch files if they don't exist..."

# Create product-service deployment patch
if [ ! -f "${REPO_ROOT}/kubernetes/overlays/uat/product-service/deployment-patch.yaml" ]; then
  echo "Creating product-service deployment patch..."
  cat > "${REPO_ROOT}/kubernetes/overlays/uat/product-service/deployment-patch.yaml" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service-blue
spec:
  replicas: 2
  template:
    spec:
      containers:
        - name: product-service
          resources:
            requests:
              memory: "256Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "300m"
          env:
            - name: NODE_ENV
              value: "uat"
            - name: LOG_LEVEL
              value: "info"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service-green
spec:
  replicas: 2
  template:
    spec:
      containers:
        - name: product-service
          resources:
            requests:
              memory: "256Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "300m"
          env:
            - name: NODE_ENV
              value: "uat"
            - name: LOG_LEVEL
              value: "info"
EOF
fi

# Create product-service service patch
if [ ! -f "${REPO_ROOT}/kubernetes/overlays/uat/product-service/service-patch.yaml" ]; then
  echo "Creating product-service service patch..."
  cat > "${REPO_ROOT}/kubernetes/overlays/uat/product-service/service-patch.yaml" << EOF
apiVersion: v1
kind: Service
metadata:
  name: product-service
  annotations:
    service.kubernetes.io/active-version: "blue"
    prometheus.io/scrape: "true"
    prometheus.io/path: "/metrics"
    prometheus.io/port: "8080"
spec:
  selector:
    app: product-service
    version: blue
    environment: uat
EOF
fi

# Create similar patches for other services...

# Apply the Kubernetes manifests
echo "Applying Kubernetes manifests..."
kubectl apply -k "${REPO_ROOT}/kubernetes/overlays/uat"

# Wait for deployments to be ready
echo "Waiting for deployments to be ready..."
kubectl rollout status deployment/product-service-blue -n ecommerce-uat --timeout=300s || true
kubectl rollout status deployment/order-service-blue -n ecommerce-uat --timeout=300s || true
kubectl rollout status deployment/user-service-blue -n ecommerce-uat --timeout=300s || true
kubectl rollout status deployment/api-gateway-blue -n ecommerce-uat --timeout=300s || true

echo "Deployment to UAT environment completed successfully!"
echo "You can access the API Gateway using the following command:"
echo "kubectl get svc api-gateway -n ecommerce-uat -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"