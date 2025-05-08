#!/bin/bash

# Script to run the QA environment on Amazon Linux 2023 EC2 instance
# This version includes ECR authentication and fixes for common issues

# Set the ECR registry URL
ECR_REGISTRY="061039790334.dkr.ecr.us-west-2.amazonaws.com"
export ECR_REGISTRY

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Path to version.json
VERSION_FILE="$SCRIPT_DIR/version.json"

# Check if version.json exists
if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: version.json not found at $VERSION_FILE"
    exit 1
fi

# Extract QA versions using grep and sed
extract_version() {
    local service=$1
    grep -A 3 "\"$service\":" "$VERSION_FILE" | grep "\"qa\":" | sed 's/.*"qa": "\(.*\)".*/\1/'
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

echo "Using the following QA versions from version.json:"
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

# Create a modified docker-compose file with Amazon Linux 2023 compatibility
TEMP_COMPOSE_FILE="$SCRIPT_DIR/docker-compose-ec2.yml"

# Copy the original docker-compose file
cp "$SCRIPT_DIR/docker-compose.yml" "$TEMP_COMPOSE_FILE"

# Update the MySQL database name to match what the backend expects
sed -i 's/MYSQL_DATABASE=ecommerce_db/MYSQL_DATABASE=notes_app/g' "$TEMP_COMPOSE_FILE"
sed -i 's/DB_NAME=ecommerce_db/DB_NAME=notes_app/g' "$TEMP_COMPOSE_FILE"

# Add retry settings for the backend service
sed -i '/DB_NAME=notes_app/a\      - DB_CONNECTION_RETRIES=5\n      - DB_CONNECTION_RETRY_DELAY=5000' "$TEMP_COMPOSE_FILE"

# Run docker-compose with the modified file
echo "Starting the QA environment..."
docker-compose -f "$TEMP_COMPOSE_FILE" up "$@"

# Clean up the temporary file when done
# trap 'rm -f "$TEMP_COMPOSE_FILE"' EXIT