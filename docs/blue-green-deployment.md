# Blue/Green Deployment for Production Environment

This guide explains how the blue/green deployment works for the production environment and how to use it effectively.

## What is Blue/Green Deployment?

Blue/green deployment is a technique that reduces downtime and risk by running two identical production environments called Blue and Green. At any time, only one of the environments is live, serving all production traffic. The other environment remains idle.

When you want to update your application:

1. Deploy the new version to the idle environment (e.g., Green if Blue is currently active)
2. Test the new version in the idle environment
3. Switch traffic from the active environment to the idle environment
4. The previously idle environment becomes active, and the previously active environment becomes idle

This approach allows for zero-downtime deployments and quick rollbacks if issues are discovered.

## Blue/Green Deployment Architecture

In our implementation, blue/green deployment is used only for the production environment. The architecture consists of:

1. **Dual Deployments**: Each microservice has two deployments in production - blue and green
2. **Service Routing**: A Kubernetes Service routes traffic to either the blue or green deployment based on selectors
3. **Traffic Switching**: A script updates the service selectors to switch traffic between blue and green

## Setting Up Blue/Green Deployment

The blue/green deployment is already set up in the production environment. The Kubernetes manifests include:

- Deployment manifests for both blue and green versions
- Service manifests that route traffic to either blue or green
- Scripts for switching traffic between blue and green

## Deploying a New Version

To deploy a new version using blue/green deployment:

### Step 1: Determine the Current Active Version

First, determine which version (blue or green) is currently active:

```bash
# Check the current active version for a service
kubectl get service product-service -n ecommerce-prod -o jsonpath='{.metadata.annotations.service\.kubernetes\.io/active-version}'
```

This will return either "blue" or "green".

### Step 2: Deploy to the Inactive Version

Deploy the new version to the inactive environment. For example, if "blue" is active, deploy to "green":

```bash
# Set environment variables
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="us-west-2"
export VERSION="1.0.1"  # New version
export DB_HOST="ecommerce-prod-db.cluster-abcdefghijkl.us-west-2.rds.amazonaws.com"
export DB_USERNAME="admin"
export DB_PASSWORD="your-secure-password"
export JWT_SECRET="your-jwt-secret"

# Update the green deployment
kubectl set image deployment/product-service-green product-service=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/ecommerce-prod/product-service:${VERSION} -n ecommerce-prod
```

### Step 3: Verify the Deployment

Verify that the new version is deployed and ready:

```bash
# Check the status of the deployment
kubectl rollout status deployment/product-service-green -n ecommerce-prod

# Verify the new version
kubectl get deployment product-service-green -n ecommerce-prod -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Step 4: Test the New Version

Test the new version before switching traffic. You can access the green version directly using its dedicated service:

```bash
# Port forward to the green service
kubectl port-forward svc/product-service-green -n ecommerce-prod 8081:8080
```

Then access the service at http://localhost:8081 for testing.

### Step 5: Switch Traffic

Once you're satisfied with the new version, switch traffic to it:

```bash
# Navigate to the scripts directory
cd /Users/colbydobson/cs/spring25/cs486/final/ecommerce-infra/scripts

# Switch traffic to green
./switch-traffic.sh product-service prod green
```

This script will:

- Update the service selector to point to the green deployment
- Update the service annotation to reflect the active version
- Optionally update the version.json file

### Step 6: Verify the Switch

Verify that traffic is now going to the green deployment:

```bash
# Check the service selector
kubectl get service product-service -n ecommerce-prod -o jsonpath='{.spec.selector.version}'

# Check the service annotation
kubectl get service product-service -n ecommerce-prod -o jsonpath='{.metadata.annotations.service\.kubernetes\.io/active-version}'
```

Both should return "green".

## Rolling Back

If issues are discovered with the new version, you can quickly roll back by switching traffic back to the previous version:

```bash
# Switch traffic back to blue
./switch-traffic.sh product-service prod blue
```

This will immediately route all traffic back to the blue deployment, effectively rolling back the change.

## Best Practices

1. **Always Test Before Switching**: Always test the new version in the inactive environment before switching traffic
2. **Automate the Process**: Use CI/CD pipelines to automate the deployment and switching process
3. **Monitor After Switching**: Monitor the application closely after switching traffic to detect any issues
4. **Keep Both Versions in Sync**: Ensure that both blue and green environments have the same configuration except for the application version
5. **Use Feature Flags**: Consider using feature flags to gradually roll out new features even within a blue/green deployment

## Troubleshooting

### 1. Traffic Not Switching

If traffic doesn't switch correctly:

```bash
# Check the service selector
kubectl get service product-service -n ecommerce-prod -o yaml
```

Ensure that the selector includes `version: blue` or `version: green` as appropriate.

### 2. Deployment Issues

If the deployment fails:

```bash
# Check the deployment status
kubectl describe deployment product-service-green -n ecommerce-prod

# Check the pod logs
kubectl logs -l app=product-service,version=green -n ecommerce-prod
```

### 3. Service Discovery Issues

If services can't communicate after switching:

```bash
# Check the endpoints
kubectl get endpoints product-service -n ecommerce-prod
```

Ensure that the endpoints are pointing to the correct pods.
