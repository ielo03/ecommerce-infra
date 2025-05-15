#!/bin/bash

# Script to run the Production environment on Amazon Linux 2023 EC2 instance
# This version includes ECR authentication and uses RDS instead of local MySQL

# Set the ECR registry URL
ECR_REGISTRY="061039790334.dkr.ecr.us-west-2.amazonaws.com"
export ECR_REGISTRY

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Ensure the infra repo is up-to-date
cd "$SCRIPT_DIR"
git pull origin main

# Path to version.json
VERSION_FILE="$SCRIPT_DIR/version.json"

# Check if version.json exists
if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: version.json not found at $VERSION_FILE"
    exit 1
fi

# Extract Production versions using grep and sed
extract_version() {
    local service=$1
    grep -A 3 "\"$service\":" "$VERSION_FILE" | grep "\"prod\":" | sed 's/.*"prod": "\(.*\)".*/\1/'
}

API_GATEWAY_VERSION=$(extract_version "api-gateway")
FRONTEND_VERSION=$(extract_version "frontend")
BACKEND_VERSION=$(extract_version "backend")

# Validate that we got the versions
if [ -z "$API_GATEWAY_VERSION" ] || [ -z "$FRONTEND_VERSION" ] || [ -z "$BACKEND_VERSION" ]; then
    echo "Error: Failed to extract versions from version.json"
    echo "Please check the format of the file"
    exit 1
fi

# Export versions as environment variables
export API_GATEWAY_VERSION
export FRONTEND_VERSION
export BACKEND_VERSION

echo "Using the following Production versions from version.json:"
echo "API Gateway: $API_GATEWAY_VERSION"
echo "Frontend: $FRONTEND_VERSION"
echo "Backend: $BACKEND_VERSION"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    echo "You can install it using: sudo yum install -y aws-cli"
    exit 1
fi

# Login to ECR - this is required to pull images
echo "Authenticating with ECR..."
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_REGISTRY

# Check if login was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to authenticate with ECR. Please check your AWS credentials."
    echo "Make sure the EC2 instance has an IAM role with ECR pull permissions."
    exit 1
fi

# Get RDS endpoint and credentials from AWS
echo "Retrieving RDS endpoint and credentials from AWS..."
RDS_SECRET_ARN=$(aws secretsmanager list-secrets --query "SecretList[?Name=='prod/notes_app_prod/credentials'].ARN" --output text)

if [ -z "$RDS_SECRET_ARN" ]; then
    echo "Error: Could not find RDS credentials in AWS Secrets Manager"
    echo "Make sure to run 'terraform apply' in the terraform/prod-rds directory first"
    exit 1
fi

RDS_SECRET=$(aws secretsmanager get-secret-value --secret-id "$RDS_SECRET_ARN" --query SecretString --output text)
DB_HOST=$(echo $RDS_SECRET | jq -r '.host')
DB_USER=$(echo $RDS_SECRET | jq -r '.username')
DB_PASSWORD=$(echo $RDS_SECRET | jq -r '.password')
DB_NAME=$(echo $RDS_SECRET | jq -r '.dbname')

echo "Retrieved RDS endpoint: $DB_HOST"

# Create a completely new docker-compose file
TEMP_COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"

# Create the new docker-compose file without MySQL (using RDS instead)
cat > "$TEMP_COMPOSE_FILE" << EOF
version: "3.8"

services:
  api-gateway:
    image: ${ECR_REGISTRY}/api-gateway:\${API_GATEWAY_VERSION:-1.0.0}
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=production
      - PORT=8080
      - FRONTEND_HOST=frontend
      - BACKEND_HOST=backend
    networks:
      - app-network
    depends_on:
      - frontend
      - backend
    healthcheck:
      test:
        [
          "CMD",
          "wget",
          "-q",
          "--spider",
          "http://localhost:8080/api-gateway/health",
        ]
      interval: 30s
      timeout: 15s
      retries: 5
      start_period: 30s

  frontend:
    image: ${ECR_REGISTRY}/frontend:\${FRONTEND_VERSION:-1.0.0}
    ports:
      - "8081:8081"
    environment:
      - NODE_ENV=production
      - PORT=8081
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:8081/health"]
      interval: 30s
      timeout: 15s
      retries: 5
      start_period: 30s

  backend:
    image: ${ECR_REGISTRY}/backend:\${BACKEND_VERSION:-1.0.0}
    ports:
      - "8082:8082"
    environment:
      - NODE_ENV=production
      - PORT=8082
      - DB_HOST=${DB_HOST}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
      - DB_NAME=${DB_NAME}
      - DB_CONNECTION_RETRIES=20
      - DB_CONNECTION_RETRY_DELAY=5000
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:8082/health"]
      interval: 30s
      timeout: 15s
      retries: 5
      start_period: 30s

networks:
  app-network:
    driver: bridge
EOF

echo "Created new docker-compose file at $TEMP_COMPOSE_FILE"

# Run docker-compose with the new file
echo "Starting the Production environment with RDS database..."
echo "Removing existing containers..."
docker-compose -f "$TEMP_COMPOSE_FILE" down
echo "Starting new containers..."
docker-compose -f "$TEMP_COMPOSE_FILE" up "$@" -d

# Wait for services to initialize
echo "Waiting for services to initialize (30 seconds)..."
sleep 30
echo "Production environment should be ready now."
echo "Using RDS database at: $DB_HOST"