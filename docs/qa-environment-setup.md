# QA Environment Setup and Connection Guide

This guide explains how to set up the QA environment and connect to it for testing and development.

## Prerequisites

Before setting up the QA environment, ensure you have the following:

1. AWS CLI installed and configured with appropriate credentials
2. kubectl installed
3. Docker installed and configured
4. Access to the ECR repositories

## Setting Up the QA Environment

### Step 1: Build and Push Docker Images

First, build and push the Docker images for all microservices to ECR:

```bash
# Navigate to the microservices directory
cd /Users/colbydobson/cs/spring25/cs486/final/ecommerce-microservices

# Build the Docker images
docker-compose build

# Log in to ECR
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com

# Tag and push the product-service image
docker tag ecommerce-microservices-product-service:latest ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/ecommerce-qa/product-service:1.0.0
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/ecommerce-qa/product-service:1.0.0

# Tag and push the order-service image
docker tag ecommerce-microservices-order-service:latest ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/ecommerce-qa/order-service:1.0.0
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/ecommerce-qa/order-service:1.0.0

# Tag and push the user-service image
docker tag ecommerce-microservices-user-service:latest ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/ecommerce-qa/user-service:1.0.0
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/ecommerce-qa/user-service:1.0.0

# Tag and push the api-gateway image
docker tag ecommerce-microservices-api-gateway:latest ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/ecommerce-qa/api-gateway:1.0.0
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/ecommerce-qa/api-gateway:1.0.0
```

### Step 2: Deploy to QA Environment

Next, deploy the microservices to the QA environment:

```bash
# Navigate to the scripts directory
cd /Users/colbydobson/cs/spring25/cs486/final/ecommerce-infra/scripts

# Set environment variables
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="us-west-2"
export VERSION="1.0.0"
export DB_HOST="ecommerce-qa-db.cluster-abcdefghijkl.us-west-2.rds.amazonaws.com"
export DB_USERNAME="admin"
export DB_PASSWORD="your-secure-password"
export JWT_SECRET="your-jwt-secret"

# Run the deployment script
./deploy-qa.sh
```

## Connecting to the QA Environment

### Step 1: Update Kubernetes Context

First, update your kubectl context to point to the QA EKS cluster:

```bash
aws eks update-kubeconfig --name ecommerce-eks-qa --region us-west-2
```

### Step 2: Verify Connection

Verify that you're connected to the correct cluster:

```bash
kubectl config current-context
```

The output should show something like:

```
arn:aws:eks:us-west-2:061039790334:cluster/ecommerce-eks-qa
```

### Step 3: List Resources in QA Namespace

List the resources in the QA namespace:

```bash
# List pods
kubectl get pods -n ecommerce-qa

# List services
kubectl get services -n ecommerce-qa

# List deployments
kubectl get deployments -n ecommerce-qa

# List configmaps
kubectl get configmaps -n ecommerce-qa

# List secrets
kubectl get secrets -n ecommerce-qa
```

### Step 4: Access the API Gateway

To access the API Gateway service in the QA environment:

```bash
# Get the API Gateway service URL
kubectl get svc api-gateway -n ecommerce-qa -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

If the API Gateway service is exposed as a LoadBalancer, this command will return the hostname of the load balancer. You can then access the API Gateway using this hostname.

### Step 5: View Logs

To view logs for a specific pod:

```bash
# Get the pod name
kubectl get pods -n ecommerce-qa

# View logs for a specific pod
kubectl logs -f <pod-name> -n ecommerce-qa
```

### Step 6: Port Forward to a Service

If you want to access a service directly from your local machine, you can use port forwarding:

```bash
# Port forward to the product service
kubectl port-forward svc/product-service -n ecommerce-qa 8080:8080
```

This command will forward port 8080 on your local machine to port 8080 on the product service. You can then access the product service at http://localhost:8080.

## Troubleshooting

### 1. Authentication Issues

If you encounter authentication issues, ensure your AWS credentials are valid:

```bash
aws sts get-caller-identity
```

This command should return your AWS account ID, user ID, and ARN. If it doesn't, your AWS credentials may be invalid or expired.

### 2. Access Issues

If you have authentication but can't access the EKS cluster, ensure you have the necessary IAM permissions:

```bash
aws eks describe-cluster --name ecommerce-eks-qa --region us-west-2
```

If this command fails with an access denied error, you may not have the necessary IAM permissions to access the EKS cluster.

### 3. Context Issues

If you're connected to the wrong cluster, check your current context:

```bash
kubectl config current-context
```

If it's not the expected context, update it using the appropriate `aws eks update-kubeconfig` command.

### 4. Network Issues

If you can't access the services, ensure your network can reach the EKS cluster:

```bash
# Get the API server endpoint
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'

# Ping the API server
ping $(echo $(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}') | sed 's/https:\/\///')
```

If the ping fails, you may have network connectivity issues.
