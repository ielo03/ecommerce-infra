# Ecommerce Platform CI/CD Pipeline

This directory contains the GitHub Actions workflows and scripts that implement the automated CI/CD pipeline for the ecommerce microservices platform.

## Overview

The CI/CD pipeline automates the testing, building, and deployment of microservices across three environments:

1. **QA** - Quality Assurance environment for initial testing
2. **UAT** - User Acceptance Testing environment for pre-production validation
3. **PROD** - Production environment for end users

The pipeline follows a progressive delivery approach with blue/green deployments and implements a promotion-based workflow where services move from QA → UAT → PROD with appropriate approvals.

## Workflow Architecture

![CI/CD Pipeline](https://mermaid.ink/img/pako:eNqNkk1PwzAMhv9KlBMgdYceuExs4sQFcUHiEKXGbaNtUuUDDVX974QWtjJtQvgS-X3s2HYuoNSCIEOlD1pVYKw-QG-Vdm5nzBEyb5Qr1Nt2q3aCXNWgHWTXV9cZbJQrQVnIXgTkUDvlwVjIxiDwqJyH7Gk9X8Fy_bh6WM5XsHlcLxcjYKOsNxYy5UE7yJ7Xq_vl3WoNm6fH-8XtCDhoNAHMCDjqxkMGFp3ywZk_wNa0HrJGOQQzAk66aQNkzaEOkLXKgvLj_6dtnPLQjoBWNc55MBPgTdv4wPz3_JOyDXgzAd60TYDpN_9fZRvwbgK8a5sA02_-SdkGvJ8A79smwPSbf1a2AR8mwIe2CTD95l-UbcDHCfCxbQJMv_lXZRvwaQJ8apsA02_-TdkGfJ4An9smwHQKfwAhFtDL?type=png)

## Key Components

### 1. Nightly CI Pipeline

The `nightly-ci.yaml` workflow runs every night at midnight UTC and:

1. Detects which microservices have changed in the last 24 hours
2. For each changed service:
   - Runs linting and unit tests
   - Builds a Docker image if tests pass
   - Pushes the image to ECR
   - Updates the version in `version.json`
   - Triggers the QA deployment workflow

### 2. QA Deployment

The `cd-qa.yaml` workflow:

1. Deploys the new version to the inactive environment (blue or green)
2. Runs health checks on the new deployment
3. Switches traffic to the new deployment
4. Triggers smoke tests

### 3. Smoke Tests

The `qa-smoke-test.yaml` workflow:

1. Runs comprehensive tests against the QA environment
2. Verifies all services are functioning correctly
3. Sends notifications on success or failure

### 4. UAT Promotion

The `promote-to-uat.yaml` workflow:

1. Manually triggered with the service to promote
2. Copies the Docker image from QA ECR to UAT ECR
3. Updates the version in `version.json`
4. Deploys to the UAT environment
5. Runs smoke tests in UAT

### 5. Production Promotion

The `promote-to-prod.yaml` workflow:

1. Manually triggered with the service to promote
2. Requires a change approval ticket number
3. Requires approval in GitHub (when environment is configured)
4. Copies the Docker image from UAT ECR to PROD ECR
5. Updates the version in `version.json`
6. Deploys to the PROD environment using blue/green deployment
7. Runs smoke tests before switching traffic

## Version Management

The `version.json` file at the root of the repository tracks the current version of each service in each environment:

```json
{
  "services": {
    "product-service": {
      "qa": "1.0.0",
      "qa_verified": true,
      "uat": "1.0.0",
      "uat_verified": false,
      "prod": "1.0.0",
      "prod_verified": false
    },
    "order-service": {
      "qa": "1.0.0",
      "qa_verified": false,
      "uat": "1.0.0",
      "uat_verified": false,
      "prod": "1.0.0",
      "prod_verified": false
    },
    "user-service": {
      "qa": "1.0.0",
      "qa_verified": false,
      "uat": "1.0.0",
      "uat_verified": false,
      "prod": "1.0.0",
      "prod_verified": false
    },
    "api-gateway": {
      "qa": "1.0.0",
      "qa_verified": false,
      "uat": "1.0.0",
      "uat_verified": false,
      "prod": "1.0.0",
      "prod_verified": false
    }
  },
  "last_updated": "2025-05-05T14:25:00Z"
}
```

The version promotion script (`version-promotion.sh`) handles updating this file and copying Docker images between environments.

## Blue/Green Deployment

The platform uses blue/green deployment to achieve zero-downtime updates:

1. Two identical environments (blue and green) are maintained
2. New versions are deployed to the inactive environment
3. Traffic is switched only after health checks pass
4. Rollbacks are quick by switching traffic back to the previous environment

The `switch-traffic.sh` script handles the traffic switching in Kubernetes.

## Workflow Files

| Workflow               | Purpose                                    |
| ---------------------- | ------------------------------------------ |
| `nightly-ci.yaml`      | Detects changes, runs tests, builds images |
| `cd-qa.yaml`           | Deploys to QA environment                  |
| `qa-smoke-test.yaml`   | Runs smoke tests in QA                     |
| `promote-to-uat.yaml`  | Promotes from QA to UAT                    |
| `promote-to-prod.yaml` | Promotes from UAT to PROD                  |

## Scripts

| Script                 | Purpose                                   |
| ---------------------- | ----------------------------------------- |
| `version-promotion.sh` | Handles version updates and image copying |

## How to Use

### Automatic Nightly Builds

The nightly CI pipeline runs automatically at midnight UTC and processes any changes to microservices.

### Manual Deployment to QA

```bash
# Trigger the workflow from GitHub UI
# Go to Actions > Deploy to QA > Run workflow
# Select the service to deploy
```

### Promoting to UAT

```bash
# Trigger the workflow from GitHub UI
# Go to Actions > Promote to UAT > Run workflow
# Select the service to promote
```

### Promoting to Production

```bash
# Trigger the workflow from GitHub UI
# Go to Actions > Promote to Production > Run workflow
# Select the service to promote
# Enter the change approval ticket number
# Approve the deployment when prompted
```

## Monitoring and Notifications

The pipeline sends notifications via:

1. Slack - for deployment success/failure
2. Email - for test failures
3. GitHub - for approval requests

## Security Considerations

- AWS credentials are stored as GitHub Secrets
- Production deployments require approval
- Change tickets are required for production deployments
