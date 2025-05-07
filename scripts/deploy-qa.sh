#!/bin/bash
# Script to deploy the ecommerce platform to the QA environment

set -e

# Set environment variables
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="us-west-2"
export VERSION="1.0.0"
export DB_HOST="ecommerce-qa-db.cluster-abcdefghijkl.us-west-2.rds.amazonaws.com"
export DB_USERNAME="admin"
export DB_PASSWORD="your-secure-password"
export JWT_SECRET="your-jwt-secret"

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Create namespace if it doesn't exist
kubectl create namespace ecommerce-qa --dry-run=client -o yaml | kubectl apply -f -

# Create secrets for each service
echo "Creating secrets for product-service..."
kubectl create secret generic product-service-secrets \
  --namespace ecommerce-qa \
  --from-literal=db_username=${DB_USERNAME} \
  --from-literal=db_password=${DB_PASSWORD} \
  --from-literal=jwt_secret=${JWT_SECRET} \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Creating secrets for order-service..."
kubectl create secret generic order-service-secrets \
  --namespace ecommerce-qa \
  --from-literal=db_username=${DB_USERNAME} \
  --from-literal=db_password=${DB_PASSWORD} \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Creating secrets for user-service..."
kubectl create secret generic user-service-secrets \
  --namespace ecommerce-qa \
  --from-literal=db_username=${DB_USERNAME} \
  --from-literal=db_password=${DB_PASSWORD} \
  --from-literal=jwt_secret=${JWT_SECRET} \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Creating secrets for api-gateway..."
kubectl create secret generic api-gateway-secrets \
  --namespace ecommerce-qa \
  --from-literal=jwt_secret=${JWT_SECRET} \
  --dry-run=client -o yaml | kubectl apply -f -

# Create ConfigMaps for each service
echo "Creating ConfigMaps for each service..."

echo "Creating ConfigMap for product-service..."
kubectl create configmap product-service-config \
  --namespace ecommerce-qa \
  --from-literal=db_host=${DB_HOST} \
  --from-literal=db_port=3306 \
  --from-literal=db_name=ecommerce_products \
  --from-literal=log_level=info \
  --from-literal=enable_inventory_check=true \
  --from-literal=enable_recommendations=false \
  --from-literal=enable_caching=true \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Creating ConfigMap for order-service..."
kubectl create configmap order-service-config \
  --namespace ecommerce-qa \
  --from-literal=db_host=${DB_HOST} \
  --from-literal=db_port=3306 \
  --from-literal=db_name=ecommerce_orders \
  --from-literal=log_level=info \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Creating ConfigMap for user-service..."
kubectl create configmap user-service-config \
  --namespace ecommerce-qa \
  --from-literal=db_host=${DB_HOST} \
  --from-literal=db_port=3306 \
  --from-literal=db_name=ecommerce_users \
  --from-literal=log_level=info \
  --dry-run=client -o yaml | kubectl apply -f -

echo "Creating ConfigMap for api-gateway..."
kubectl create configmap api-gateway-config \
  --namespace ecommerce-qa \
  --from-literal=product_service_url=http://product-service:8080 \
  --from-literal=order_service_url=http://order-service:8080 \
  --from-literal=user_service_url=http://user-service:8080 \
  --from-literal=log_level=info \
  --dry-run=client -o yaml | kubectl apply -f -

# Check if the required directories exist
echo "Checking if required directories exist..."
if [ ! -d "${REPO_ROOT}/kubernetes/overlays/qa/product-service" ]; then
  echo "Creating product-service directory..."
  mkdir -p "${REPO_ROOT}/kubernetes/overlays/qa/product-service"
fi

if [ ! -d "${REPO_ROOT}/kubernetes/overlays/qa/order-service" ]; then
  echo "Creating order-service directory..."
  mkdir -p "${REPO_ROOT}/kubernetes/overlays/qa/order-service"
fi

if [ ! -d "${REPO_ROOT}/kubernetes/overlays/qa/user-service" ]; then
  echo "Creating user-service directory..."
  mkdir -p "${REPO_ROOT}/kubernetes/overlays/qa/user-service"
fi

if [ ! -d "${REPO_ROOT}/kubernetes/overlays/qa/api-gateway" ]; then
  echo "Creating api-gateway directory..."
  mkdir -p "${REPO_ROOT}/kubernetes/overlays/qa/api-gateway"
fi

# Create deployment files if they don't exist
echo "Creating deployment files if they don't exist..."

# Create product-service deployment-blue.yaml
if [ ! -f "${REPO_ROOT}/kubernetes/overlays/qa/product-service/deployment-blue.yaml" ]; then
  echo "Creating product-service deployment-blue.yaml..."
  cat > "${REPO_ROOT}/kubernetes/overlays/qa/product-service/deployment-blue.yaml" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service-blue
  namespace: ecommerce-qa
  labels:
    app: product-service
    version: blue
    environment: qa
    app.kubernetes.io/name: product-service
    app.kubernetes.io/part-of: ecommerce-platform
spec:
  replicas: 2
  selector:
    matchLabels:
      app: product-service
      version: blue
      environment: qa
  template:
    metadata:
      labels:
        app: product-service
        version: blue
        environment: qa
        app.kubernetes.io/name: product-service
        app.kubernetes.io/part-of: ecommerce-platform
    spec:
      containers:
      - name: product-service
        image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecommerce-qa/product-service:${VERSION}
        ports:
        - containerPort: 8080
        env:
        - name: NODE_ENV
          value: "qa"
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: product-service-config
              key: db_host
        - name: DB_PORT
          valueFrom:
            configMapKeyRef:
              name: product-service-config
              key: db_port
        - name: DB_NAME
          valueFrom:
            configMapKeyRef:
              name: product-service-config
              key: db_name
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: product-service-secrets
              key: db_username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: product-service-secrets
              key: db_password
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: product-service-secrets
              key: jwt_secret
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "300m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 30
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3
EOF
fi

# Create product-service deployment-green.yaml
if [ ! -f "${REPO_ROOT}/kubernetes/overlays/qa/product-service/deployment-green.yaml" ]; then
  echo "Creating product-service deployment-green.yaml..."
  cat > "${REPO_ROOT}/kubernetes/overlays/qa/product-service/deployment-green.yaml" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service-green
  namespace: ecommerce-qa
  labels:
    app: product-service
    version: green
    environment: qa
    app.kubernetes.io/name: product-service
    app.kubernetes.io/part-of: ecommerce-platform
spec:
  replicas: 2
  selector:
    matchLabels:
      app: product-service
      version: green
      environment: qa
  template:
    metadata:
      labels:
        app: product-service
        version: green
        environment: qa
        app.kubernetes.io/name: product-service
        app.kubernetes.io/part-of: ecommerce-platform
    spec:
      containers:
      - name: product-service
        image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecommerce-qa/product-service:${VERSION}
        ports:
        - containerPort: 8080
        env:
        - name: NODE_ENV
          value: "qa"
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: product-service-config
              key: db_host
        - name: DB_PORT
          valueFrom:
            configMapKeyRef:
              name: product-service-config
              key: db_port
        - name: DB_NAME
          valueFrom:
            configMapKeyRef:
              name: product-service-config
              key: db_name
        - name: DB_USERNAME
          valueFrom:
            secretKeyRef:
              name: product-service-secrets
              key: db_username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: product-service-secrets
              key: db_password
        - name: JWT_SECRET
          valueFrom:
            secretKeyRef:
              name: product-service-secrets
              key: jwt_secret
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "300m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 30
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 3
          failureThreshold: 3
EOF
fi

# Create product-service service.yaml
if [ ! -f "${REPO_ROOT}/kubernetes/overlays/qa/product-service/service.yaml" ]; then
  echo "Creating product-service service.yaml..."
  cat > "${REPO_ROOT}/kubernetes/overlays/qa/product-service/service.yaml" << EOF
apiVersion: v1
kind: Service
metadata:
  name: product-service
  namespace: ecommerce-qa
  labels:
    app: product-service
    environment: qa
    app.kubernetes.io/name: product-service
    app.kubernetes.io/part-of: ecommerce-platform
  annotations:
    service.kubernetes.io/active-version: "blue"
    prometheus.io/scrape: "true"
    prometheus.io/path: "/metrics"
    prometheus.io/port: "8080"
spec:
  selector:
    app: product-service
    version: blue
    environment: qa
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
EOF
fi

# Create product-service service-blue.yaml
if [ ! -f "${REPO_ROOT}/kubernetes/overlays/qa/product-service/service-blue.yaml" ]; then
  echo "Creating product-service service-blue.yaml..."
  cat > "${REPO_ROOT}/kubernetes/overlays/qa/product-service/service-blue.yaml" << EOF
apiVersion: v1
kind: Service
metadata:
  name: product-service-blue
  namespace: ecommerce-qa
  labels:
    app: product-service
    version: blue
    environment: qa
    app.kubernetes.io/name: product-service
    app.kubernetes.io/part-of: ecommerce-platform
spec:
  selector:
    app: product-service
    version: blue
    environment: qa
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
EOF
fi

# Create product-service service-green.yaml
if [ ! -f "${REPO_ROOT}/kubernetes/overlays/qa/product-service/service-green.yaml" ]; then
  echo "Creating product-service service-green.yaml..."
  cat > "${REPO_ROOT}/kubernetes/overlays/qa/product-service/service-green.yaml" << EOF
apiVersion: v1
kind: Service
metadata:
  name: product-service-green
  namespace: ecommerce-qa
  labels:
    app: product-service
    version: green
    environment: qa
    app.kubernetes.io/name: product-service
    app.kubernetes.io/part-of: ecommerce-platform
spec:
  selector:
    app: product-service
    version: green
    environment: qa
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
EOF
fi

# Create similar files for other services...

# Apply the Kubernetes manifests
echo "Applying Kubernetes manifests..."
kubectl apply -f "${REPO_ROOT}/kubernetes/overlays/qa/product-service/deployment-blue.yaml"
kubectl apply -f "${REPO_ROOT}/kubernetes/overlays/qa/product-service/deployment-green.yaml"
kubectl apply -f "${REPO_ROOT}/kubernetes/overlays/qa/product-service/service.yaml"
kubectl apply -f "${REPO_ROOT}/kubernetes/overlays/qa/product-service/service-blue.yaml"
kubectl apply -f "${REPO_ROOT}/kubernetes/overlays/qa/product-service/service-green.yaml"

# Wait for deployments to be ready
echo "Waiting for deployments to be ready..."
kubectl rollout status deployment/product-service-blue -n ecommerce-qa --timeout=300s || true

echo "Deployment to QA environment completed successfully!"
echo "You can access the API Gateway using the following command:"
echo "kubectl get svc api-gateway -n ecommerce-qa -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"