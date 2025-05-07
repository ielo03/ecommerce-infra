# QA Environment Setup and Connection Guide

This document provides instructions for setting up and connecting to the QA environment for the E-Commerce microservices platform.

## Overview

The QA environment is deployed on AWS EKS and consists of the following components:

- API Gateway
- Product Service
- Order Service
- User Service
- MySQL Database
- Monitoring Stack (Prometheus, Grafana, Alertmanager)

## Current Status

Currently, the QA environment is running with placeholder nginx containers instead of the actual microservices. When you access the API Gateway URL directly, you'll see the default nginx welcome page:

```
Welcome to nginx!
If you see this page, the nginx web server is successfully installed and working. Further configuration is required.
```

This is expected in this demo setup. The infrastructure is correctly provisioned, but the actual microservices need to be implemented and deployed.

## Accessing the QA Environment

### Prerequisites

- AWS CLI configured with appropriate credentials
- kubectl installed and configured
- Access to the GitHub repository

### Step 1: Configure kubectl for the QA EKS Cluster

```bash
aws eks update-kubeconfig --name ecommerce-eks-qa --region us-west-2
```

### Step 2: Verify Access to the Cluster

```bash
kubectl get nodes
```

You should see the nodes in the QA EKS cluster.

### Step 3: Check the Status of the QA Environment

```bash
kubectl get pods -n ecommerce-qa
```

This will show all the pods running in the QA environment.

```bash
kubectl get services -n ecommerce-qa
```

This will show all the services in the QA environment, including the API Gateway LoadBalancer.

## API Gateway Access

The API Gateway is exposed as a LoadBalancer service. You can access it using the following URL:

```
http://a66d7a4e770c648488eb7ceedaed5de3-1091165914.us-west-2.elb.amazonaws.com
```

To get the current URL, run:

```bash
kubectl get service api-gateway -n ecommerce-qa -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Testing the API Gateway

You can test the API Gateway using curl:

```bash
# Check if the API Gateway is accessible
curl -I http://a66d7a4e770c648488eb7ceedaed5de3-1091165914.us-west-2.elb.amazonaws.com

# You should see the default nginx welcome page
curl http://a66d7a4e770c648488eb7ceedaed5de3-1091165914.us-west-2.elb.amazonaws.com
```

## Using the Frontend Demo

A simple frontend demo is provided to interact with the QA environment. To use it:

1. Navigate to the frontend-demo directory:

   ```bash
   cd /Users/colbydobson/cs/spring25/cs486/final/ecommerce-microservices/frontend-demo
   ```

2. Run the provided script to open the frontend in your browser:

   ```bash
   ./open-qa-frontend.sh
   ```

3. The frontend will open in your default browser and is configured to connect to the QA environment's API Gateway.

Note: Since we're using placeholder nginx containers, the API calls from the frontend will not return actual data until the microservices are fully implemented.

## Deploying to the QA Environment

### Manual Deployment

To manually deploy to the QA environment:

```bash
cd /Users/colbydobson/cs/spring25/cs486/final/ecommerce-infra/scripts
./deploy-qa.sh
```

This script will:

1. Create the ecommerce-qa namespace if it doesn't exist
2. Create ConfigMaps and Secrets for each service
3. Apply the Kubernetes manifests for all services

### Automated Deployment via CI/CD

The CI/CD pipeline automatically deploys to the QA environment when:

1. Changes are pushed to the main branch
2. The nightly build workflow runs
3. The version.json file is updated

## Steps to Fully Implement the Microservices

To fully implement the microservices:

1. Build the actual microservice Docker images:

   ```bash
   cd /Users/colbydobson/cs/spring25/cs486/final/ecommerce-microservices
   docker-compose build
   ```

2. Push the images to ECR:

   ```bash
   # Get the AWS account ID
   export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

   # Log in to ECR
   aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com

   # Create ECR repositories if they don't exist
   aws ecr create-repository --repository-name ecommerce-qa/api-gateway --region us-west-2
   aws ecr create-repository --repository-name ecommerce-qa/product-service --region us-west-2
   aws ecr create-repository --repository-name ecommerce-qa/order-service --region us-west-2
   aws ecr create-repository --repository-name ecommerce-qa/user-service --region us-west-2

   # Tag and push the images
   docker tag ecommerce-microservices-api-gateway:latest ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/ecommerce-qa/api-gateway:1.0.0
   docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/ecommerce-qa/api-gateway:1.0.0

   docker tag ecommerce-microservices-product-service:latest ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/ecommerce-qa/product-service:1.0.0
   docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/ecommerce-qa/product-service:1.0.0

   docker tag ecommerce-microservices-order-service:latest ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/ecommerce-qa/order-service:1.0.0
   docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/ecommerce-qa/order-service:1.0.0

   docker tag ecommerce-microservices-user-service:latest ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/ecommerce-qa/user-service:1.0.0
   docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/ecommerce-qa/user-service:1.0.0
   ```

3. Update the deployment files to use the actual images:

   ```bash
   # Update the image references in the deployment files
   cd /Users/colbydobson/cs/spring25/cs486/final/ecommerce-infra/kubernetes/overlays/qa

   # For each service, update the deployment files to use the actual images
   # Example for api-gateway:
   sed -i '' "s|image: nginx:latest|image: ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/ecommerce-qa/api-gateway:1.0.0|g" api-gateway/deployment-blue.yaml
   sed -i '' "s|image: nginx:latest|image: ${AWS_ACCOUNT_ID}.dkr.ecr.us-west-2.amazonaws.com/ecommerce-qa/api-gateway:1.0.0|g" api-gateway/deployment-green.yaml

   # Repeat for other services
   ```

4. Redeploy the services:
   ```bash
   cd /Users/colbydobson/cs/spring25/cs486/final/ecommerce-infra/scripts
   ./deploy-qa.sh
   ```

## Blue/Green Deployment

The QA environment uses blue/green deployment for zero-downtime updates. To switch traffic between blue and green deployments:

```bash
cd /Users/colbydobson/cs/spring25/cs486/final/ecommerce-infra/kubernetes/blue-green/scripts
./switch-traffic.sh -n ecommerce-qa -s product-service -v green
```

Replace `product-service` with the service you want to switch, and `green` with the version you want to switch to (`blue` or `green`).

## Troubleshooting

### Common Issues

1. **Pods in ImagePullBackOff or ErrImagePull state**

   - Check if the Docker images exist in ECR
   - Verify that the image names and tags in the deployment files are correct

2. **Services not accessible**

   - Check if the pods are running and ready
   - Verify that the services have endpoints
   - Check if the LoadBalancer has been provisioned

3. **Database connection issues**
   - Verify that the database secrets are correctly configured
   - Check if the database is accessible from the EKS cluster

### Useful Commands

```bash
# Get detailed information about a pod
kubectl describe pod <pod-name> -n ecommerce-qa

# View logs for a pod
kubectl logs <pod-name> -n ecommerce-qa

# Check endpoints for a service
kubectl get endpoints -n ecommerce-qa

# Port-forward to a service for local testing
kubectl port-forward svc/<service-name> -n ecommerce-qa 8080:80
```

## Additional Resources

- [Connecting to Environments](./connecting-to-environments.md)
- [Blue/Green Deployment](./blue-green-deployment.md)
- [GitHub Secrets Setup](./github-secrets-setup.md)
