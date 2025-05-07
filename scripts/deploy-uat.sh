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

# Update kustomization files with correct image names
echo "Updating kustomization files with correct image names..."

# Update product-service kustomization
sed -i '' "s|\${ECR_REPOSITORY}/product-service|ecommerce-uat/product-service|g" kubernetes/overlays/uat/product-service/kustomization.yaml
sed -i '' "s|\${AWS_ACCOUNT_ID}|${AWS_ACCOUNT_ID}|g" kubernetes/overlays/uat/product-service/kustomization.yaml
sed -i '' "s|\${AWS_REGION}|${AWS_REGION}|g" kubernetes/overlays/uat/product-service/kustomization.yaml
sed -i '' "s|\${VERSION}|${VERSION}|g" kubernetes/overlays/uat/product-service/kustomization.yaml
sed -i '' "s|\${DB_HOST}|${DB_HOST}|g" kubernetes/overlays/uat/product-service/kustomization.yaml
sed -i '' "s|\${DB_USERNAME}|${DB_USERNAME}|g" kubernetes/overlays/uat/product-service/kustomization.yaml
sed -i '' "s|\${DB_PASSWORD}|${DB_PASSWORD}|g" kubernetes/overlays/uat/product-service/kustomization.yaml
sed -i '' "s|\${JWT_SECRET}|${JWT_SECRET}|g" kubernetes/overlays/uat/product-service/kustomization.yaml

# Update order-service kustomization (assuming similar structure)
sed -i '' "s|\${ECR_REPOSITORY}/order-service|ecommerce-uat/order-service|g" kubernetes/overlays/uat/order-service/kustomization.yaml
sed -i '' "s|\${AWS_ACCOUNT_ID}|${AWS_ACCOUNT_ID}|g" kubernetes/overlays/uat/order-service/kustomization.yaml
sed -i '' "s|\${AWS_REGION}|${AWS_REGION}|g" kubernetes/overlays/uat/order-service/kustomization.yaml
sed -i '' "s|\${VERSION}|${VERSION}|g" kubernetes/overlays/uat/order-service/kustomization.yaml
sed -i '' "s|\${DB_HOST}|${DB_HOST}|g" kubernetes/overlays/uat/order-service/kustomization.yaml
sed -i '' "s|\${DB_USERNAME}|${DB_USERNAME}|g" kubernetes/overlays/uat/order-service/kustomization.yaml
sed -i '' "s|\${DB_PASSWORD}|${DB_PASSWORD}|g" kubernetes/overlays/uat/order-service/kustomization.yaml
sed -i '' "s|\${JWT_SECRET}|${JWT_SECRET}|g" kubernetes/overlays/uat/order-service/kustomization.yaml

# Update user-service kustomization (assuming similar structure)
sed -i '' "s|\${ECR_REPOSITORY}/user-service|ecommerce-uat/user-service|g" kubernetes/overlays/uat/user-service/kustomization.yaml
sed -i '' "s|\${AWS_ACCOUNT_ID}|${AWS_ACCOUNT_ID}|g" kubernetes/overlays/uat/user-service/kustomization.yaml
sed -i '' "s|\${AWS_REGION}|${AWS_REGION}|g" kubernetes/overlays/uat/user-service/kustomization.yaml
sed -i '' "s|\${VERSION}|${VERSION}|g" kubernetes/overlays/uat/user-service/kustomization.yaml
sed -i '' "s|\${DB_HOST}|${DB_HOST}|g" kubernetes/overlays/uat/user-service/kustomization.yaml
sed -i '' "s|\${DB_USERNAME}|${DB_USERNAME}|g" kubernetes/overlays/uat/user-service/kustomization.yaml
sed -i '' "s|\${DB_PASSWORD}|${DB_PASSWORD}|g" kubernetes/overlays/uat/user-service/kustomization.yaml
sed -i '' "s|\${JWT_SECRET}|${JWT_SECRET}|g" kubernetes/overlays/uat/user-service/kustomization.yaml

# Update api-gateway kustomization (assuming similar structure)
sed -i '' "s|\${ECR_REPOSITORY}/api-gateway|ecommerce-uat/api-gateway|g" kubernetes/overlays/uat/api-gateway/kustomization.yaml
sed -i '' "s|\${AWS_ACCOUNT_ID}|${AWS_ACCOUNT_ID}|g" kubernetes/overlays/uat/api-gateway/kustomization.yaml
sed -i '' "s|\${AWS_REGION}|${AWS_REGION}|g" kubernetes/overlays/uat/api-gateway/kustomization.yaml
sed -i '' "s|\${VERSION}|${VERSION}|g" kubernetes/overlays/uat/api-gateway/kustomization.yaml
sed -i '' "s|\${JWT_SECRET}|${JWT_SECRET}|g" kubernetes/overlays/uat/api-gateway/kustomization.yaml

# Apply the Kubernetes manifests
echo "Applying Kubernetes manifests..."
kubectl apply -k kubernetes/overlays/uat

# Wait for deployments to be ready
echo "Waiting for deployments to be ready..."
kubectl rollout status deployment/product-service-blue -n ecommerce-uat --timeout=300s
kubectl rollout status deployment/order-service-blue -n ecommerce-uat --timeout=300s
kubectl rollout status deployment/user-service-blue -n ecommerce-uat --timeout=300s
kubectl rollout status deployment/api-gateway-blue -n ecommerce-uat --timeout=300s

echo "Deployment to UAT environment completed successfully!"
echo "You can access the API Gateway using the following command:"
echo "kubectl get svc api-gateway -n ecommerce-uat -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"