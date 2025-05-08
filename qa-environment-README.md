# QA Environment Setup

This directory contains Docker Compose configuration to run the QA environment using the latest QA versions of each microservice from ECR.

## Prerequisites

- Docker and Docker Compose installed
- AWS CLI configured with appropriate permissions to pull from ECR
- `jq` installed (for parsing JSON) - optional, an alternative script is provided

## How It Works

The setup consists of the following files:

1. `docker-compose.yml` - Defines the services and their configurations
2. `run-qa-environment.sh` - Helper script that reads version information using jq and starts the environment
3. `run-qa-environment-no-jq.sh` - Alternative helper script that doesn't require jq (uses grep/sed instead)

The scripts read the QA versions from `version.json` and set them as environment variables for Docker Compose to use when pulling images.

## Usage

To start the QA environment:

```bash
# Make sure the script is executable
chmod +x run-qa-environment.sh

# Run the environment
./run-qa-environment.sh
```

If you don't have jq installed, you can use the alternative script:

```bash
chmod +x run-qa-environment-no-jq.sh
./run-qa-environment-no-jq.sh
```

This will:

1. Read the QA versions from `version.json`
2. Pull the appropriate images from ECR (061039790334.dkr.ecr.us-west-2.amazonaws.com)
3. Start all the services

### Additional Options

You can pass any standard Docker Compose flags to the script:

```bash
# Run in detached mode
./run-qa-environment.sh -d

# Scale a specific service
./run-qa-environment.sh --scale backend=2

# Stop the environment
./run-qa-environment.sh down
```

## Services

The environment includes the following services:

- **api-gateway**: API Gateway service (port 8080)
- **frontend**: Frontend service (port 8081)
- **backend**: Backend service (port 8082)
- **mysql**: MySQL database for the backend service (port 3306)

## Accessing the Services

Once running, you can access the services at:

- API Gateway: http://localhost:8080
- Frontend: http://localhost:8081
- Backend: http://localhost:8082

## Troubleshooting

### ECR Login Issues

If you encounter issues pulling images from ECR, you may need to authenticate:

```bash
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 061039790334.dkr.ecr.us-west-2.amazonaws.com
```

### Version Issues

If you need to override the versions from `version.json`, you can set the environment variables manually:

```bash
export API_GATEWAY_VERSION=1.0.1
export FRONTEND_VERSION=1.0.1
export BACKEND_VERSION=1.0.1
./run-qa-environment.sh
```

### Image Pulling Issues

If you're having trouble pulling the images, you can verify the image tags with:

```bash
aws ecr describe-images --repository-name api-gateway --region us-west-2 --registry-id 061039790334
aws ecr describe-images --repository-name frontend --region us-west-2 --registry-id 061039790334
aws ecr describe-images --repository-name backend --region us-west-2 --registry-id 061039790334
```
