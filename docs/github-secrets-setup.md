# Setting Up GitHub Secrets for CI/CD Pipeline

This guide explains how to set up the necessary GitHub Secrets for the CI/CD pipeline to work correctly.

## Required Secrets

The following secrets need to be set up in your GitHub repository:

### AWS Credentials

These secrets are used to authenticate with AWS services like ECR and EKS:

1. `AWS_ACCESS_KEY_ID`: Your AWS access key ID
2. `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key
3. `AWS_REGION`: The AWS region where your resources are deployed (e.g., `us-west-2`)

### Database Credentials

These secrets are used to connect to the databases in different environments:

1. `QA_DB_HOST`: The hostname of the QA database
2. `QA_DB_USERNAME`: The username for the QA database
3. `QA_DB_PASSWORD`: The password for the QA database

4. `UAT_DB_HOST`: The hostname of the UAT database
5. `UAT_DB_USERNAME`: The username for the UAT database
6. `UAT_DB_PASSWORD`: The password for the UAT database

7. `PROD_DB_HOST`: The hostname of the Production database
8. `PROD_DB_USERNAME`: The username for the Production database
9. `PROD_DB_PASSWORD`: The password for the Production database

### JWT Secrets

These secrets are used for authentication in the microservices:

1. `QA_JWT_SECRET`: The JWT secret for the QA environment
2. `UAT_JWT_SECRET`: The JWT secret for the UAT environment
3. `PROD_JWT_SECRET`: The JWT secret for the Production environment

### EKS Cluster Names

These secrets specify the names of the EKS clusters:

1. `QA_EKS_CLUSTER_NAME`: The name of the QA EKS cluster (e.g., `ecommerce-eks-qa`)
2. `UAT_EKS_CLUSTER_NAME`: The name of the UAT EKS cluster (e.g., `ecommerce-eks-uat`)
3. `PROD_EKS_CLUSTER_NAME`: The name of the Production EKS cluster (e.g., `ecommerce-eks-prod`)

## Setting Up Secrets in GitHub

To set up these secrets in your GitHub repository:

1. Go to your GitHub repository
2. Click on "Settings"
3. In the left sidebar, click on "Secrets and variables" > "Actions"
4. Click on "New repository secret"
5. Enter the name of the secret (e.g., `AWS_ACCESS_KEY_ID`)
6. Enter the value of the secret
7. Click on "Add secret"
8. Repeat for all required secrets

## Using Secrets in GitHub Actions Workflows

The secrets are referenced in the GitHub Actions workflows using the `${{ secrets.SECRET_NAME }}` syntax. For example:

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v1
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ secrets.AWS_REGION }}
```

## Environment-Specific Secrets

For environment-specific workflows, you can set up GitHub Environments with their own secrets:

1. Go to your GitHub repository
2. Click on "Settings"
3. In the left sidebar, click on "Environments"
4. Click on "New environment"
5. Enter the name of the environment (e.g., `qa`, `uat`, `production`)
6. Click on "Configure environment"
7. Add environment-specific secrets
8. Optionally, add protection rules like required reviewers

This allows you to have different secrets for different environments and add approval requirements for sensitive environments like production.

## Secret Rotation

For security reasons, it's recommended to rotate your secrets periodically:

1. Generate new credentials in AWS
2. Update the secrets in GitHub
3. Revoke the old credentials in AWS

## Troubleshooting

If you encounter issues with the CI/CD pipeline related to secrets:

1. Check that all required secrets are set up correctly
2. Verify that the secret names match those used in the workflows
3. Ensure that the AWS credentials have the necessary permissions
4. Check the GitHub Actions logs for any error messages related to authentication or authorization
