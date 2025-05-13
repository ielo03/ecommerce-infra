# UAT Environment RDS Setup Guide (Simplified Approach)

This guide explains how to set up and use the Amazon RDS database for the UAT environment instead of a local MySQL container.

## Overview

The UAT environment has been updated to use an Amazon RDS MySQL database instead of a local MySQL container. This provides several benefits:

- More stable and reliable database service
- Persistent storage that survives container restarts
- Better separation of concerns between application and database
- More production-like environment for testing

## Prerequisites

- AWS CLI installed and configured with appropriate permissions
- Terraform installed (version 0.14 or later)
- Docker and Docker Compose installed

## Step 1: Deploy the RDS Database with Terraform

We've created a simplified, standalone Terraform configuration specifically for the RDS instance to avoid any issues with existing Terraform state or backend configurations.

1. Navigate to the new UAT RDS Terraform directory:

```bash
cd ecommerce-infra/terraform/uat-rds
```

2. Initialize Terraform:

```bash
terraform init
```

3. Apply the Terraform configuration:

```bash
terraform apply
```

4. When prompted, review the changes and type `yes` to proceed.

5. After the deployment completes, note the RDS endpoint in the outputs:

```
rds_endpoint = "uat-notes-db.abcdefghijkl.us-west-2.rds.amazonaws.com:3306"
```

## Step 2: Run the UAT Environment

The `run-uat-environment-ec2.sh` script has been updated to automatically:

1. Retrieve the RDS endpoint and credentials from AWS Secrets Manager
2. Configure the backend service to connect to the RDS database
3. Start the containers without the local MySQL container

To run the UAT environment:

```bash
cd ecommerce-infra
./run-uat-environment-ec2.sh
```

## How It Works

### Simplified Terraform Configuration

The new Terraform configuration in `ecommerce-infra/terraform/uat-rds/main.tf` creates:

1. A dedicated VPC with DNS support and DNS hostnames enabled
2. Public subnets with internet access for the RDS instance
3. Security groups to allow database access
4. An RDS MySQL instance with the database name `notes_app_uat`
5. AWS Secrets Manager secret to store the database credentials

This standalone configuration avoids any issues with existing Terraform state or backend configurations and ensures the RDS instance is properly accessible.

> **Note**: The VPC is configured with `enable_dns_support` and `enable_dns_hostnames` set to true, which is required for publicly accessible RDS instances.

### UAT Environment Script

The `run-uat-environment-ec2.sh` script:

1. Retrieves the RDS endpoint and credentials from AWS Secrets Manager
2. Creates a docker-compose file without the MySQL service
3. Configures the backend service to connect to the RDS database
4. Starts the containers

## Troubleshooting

### Cannot connect to the RDS database

- Verify that the RDS instance is running in the AWS Console
- Check that the security group allows connections from the EC2 instance
- Ensure the EC2 instance has the necessary IAM permissions to access Secrets Manager

### Missing RDS credentials in Secrets Manager

- Make sure you've run `terraform apply` in the uat-rds directory
- Check that the secret name follows the pattern: `uat/notes_app_uat/credentials`

### Backend service fails to start

- Check the backend logs: `docker logs backend`
- Verify that the RDS endpoint is correct and accessible
- Ensure the database exists in the RDS instance
