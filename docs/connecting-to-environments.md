# Connecting to Ecommerce Platform Environments

This guide explains how to connect to the different environments (QA, UAT, Production) of the ecommerce platform.

## Prerequisites

Before connecting to any environment, ensure you have the following:

1. AWS CLI installed and configured with appropriate credentials
2. kubectl installed
3. AWS IAM permissions to access the EKS clusters
4. AWS EKS cluster credentials configured

## Connecting to the QA Environment

### 1. Update Kubernetes Context

First, update your kubectl context to point to the QA EKS cluster:

```bash
aws eks update-kubeconfig --name ecommerce-eks-qa --region us-west-2
```

This command will update your kubeconfig file with the credentials for the QA EKS cluster.

### 2. Verify Connection

Verify that you're connected to the correct cluster:

```bash
kubectl config current-context
```

The output should show something like:

```
arn:aws:eks:us-west-2:061039790334:cluster/ecommerce-eks-qa
```

### 3. List Resources in QA Namespace

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

### 4. Access the API Gateway

To access the API Gateway service in the QA environment:

```bash
# Get the API Gateway service URL
kubectl get svc api-gateway -n ecommerce-qa -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

If the API Gateway service is exposed as a LoadBalancer, this command will return the hostname of the load balancer. You can then access the API Gateway using this hostname.

### 5. View Logs

To view logs for a specific pod:

```bash
# Get the pod name
kubectl get pods -n ecommerce-qa

# View logs for a specific pod
kubectl logs -f <pod-name> -n ecommerce-qa
```

### 6. Port Forward to a Service

If you want to access a service directly from your local machine, you can use port forwarding:

```bash
# Port forward to the product service
kubectl port-forward svc/product-service -n ecommerce-qa 8080:8080
```

This command will forward port 8080 on your local machine to port 8080 on the product service. You can then access the product service at http://localhost:8080.

## Connecting to the UAT Environment

Follow the same steps as for the QA environment, but replace `ecommerce-eks-qa` with `ecommerce-eks-uat` and `ecommerce-qa` with `ecommerce-uat`.

```bash
# Update kubeconfig
aws eks update-kubeconfig --name ecommerce-eks-uat --region us-west-2

# List resources
kubectl get pods -n ecommerce-uat
```

## Connecting to the Production Environment

Follow the same steps as for the QA environment, but replace `ecommerce-eks-qa` with `ecommerce-eks-prod` and `ecommerce-qa` with `ecommerce-prod`.

```bash
# Update kubeconfig
aws eks update-kubeconfig --name ecommerce-eks-prod --region us-west-2

# List resources
kubectl get pods -n ecommerce-prod
```

## Switching Between Environments

You can easily switch between environments by updating your kubectl context:

```bash
# Switch to QA
aws eks update-kubeconfig --name ecommerce-eks-qa --region us-west-2

# Switch to UAT
aws eks update-kubeconfig --name ecommerce-eks-uat --region us-west-2

# Switch to Production
aws eks update-kubeconfig --name ecommerce-eks-prod --region us-west-2
```

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
