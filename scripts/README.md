# Ecommerce Platform Deployment Scripts

This directory contains scripts for deploying the ecommerce platform to different environments.

## Prerequisites

Before running these scripts, ensure you have the following:

1. AWS CLI configured with appropriate credentials
2. kubectl installed and configured to access your EKS clusters
3. Docker installed and configured
4. Access to the ECR repositories
5. jq installed for JSON processing

## Available Scripts

### deploy-all.sh

This is the main deployment script that provides a menu-driven interface for deploying to different environments.

```bash
./deploy-all.sh
```

### deploy-qa.sh

This script deploys the ecommerce platform to the QA environment.

```bash
./deploy-qa.sh
```

### deploy-uat.sh

This script deploys the ecommerce platform to the UAT environment.

```bash
./deploy-uat.sh
```

### deploy-prod.sh

This script deploys the ecommerce platform to the Production environment.

```bash
./deploy-prod.sh
```

### update-version.sh

This script updates the version.json file when promoting services between environments. It's used to trigger GitOps-style deployments.

```bash
./update-version.sh <service> <source-env> <target-env> [version]
```

Examples:

```bash
# Promote product-service from QA to UAT using the current QA version
./update-version.sh product-service qa uat

# Promote order-service from UAT to Production with a specific version
./update-version.sh order-service uat prod 1.0.1
```

## Deployment Process

The deployment process for each environment follows these steps:

1. Set environment variables
2. Create the namespace if it doesn't exist
3. Create secrets for each service
4. Update kustomization files with correct image names
5. Apply the Kubernetes manifests
6. Wait for deployments to be ready

## GitOps-Style Deployments

The platform uses a GitOps approach where changes to the `version.json` file drive deployments:

1. The `update-version.sh` script updates the version.json file
2. The version-watcher workflow detects the change and triggers the appropriate deployment workflow
3. The deployment workflow deploys the service to the target environment

## Blue/Green Deployment

The platform uses blue/green deployment to achieve zero-downtime updates:

1. Two identical environments (blue and green) are maintained
2. New versions are deployed to the inactive environment
3. Traffic is switched only after health checks pass
4. Rollbacks are quick by switching traffic back to the previous environment

## Customizing Deployments

You can customize the deployments by modifying the environment variables at the top of each deployment script:

```bash
# Set environment variables
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="us-west-2"
export VERSION="1.0.0"
export DB_HOST="ecommerce-qa-db.cluster-abcdefghijkl.us-west-2.rds.amazonaws.com"
export DB_USERNAME="admin"
export DB_PASSWORD="your-secure-password"
export JWT_SECRET="your-jwt-secret"
```

## Troubleshooting

If you encounter issues during deployment, check the following:

1. Ensure your AWS credentials are valid
2. Verify that you have access to the ECR repositories
3. Check that your kubectl context is set to the correct cluster
4. Verify that the environment variables are set correctly
5. Check the logs of the deployed pods for any errors

```bash
kubectl logs -f <pod-name> -n ecommerce-<env>
```

## Security Considerations

The deployment scripts create Kubernetes secrets for storing sensitive information such as database credentials and JWT secrets. In a production environment, consider using a more secure solution such as AWS Secrets Manager or HashiCorp Vault.
