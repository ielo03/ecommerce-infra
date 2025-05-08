#!/bin/bash

# Script to run the QA environment using versions from version.json

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

# Extract QA versions using jq (make sure jq is installed)
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Please install jq first."
    echo "You can install it using: apt-get install jq (Ubuntu/Debian) or brew install jq (macOS)"
    exit 1
fi

# Extract versions from version.json
API_GATEWAY_VERSION=$(jq -r '.services."api-gateway".qa' "$VERSION_FILE")
FRONTEND_VERSION=$(jq -r '.services.frontend.qa' "$VERSION_FILE")
BACKEND_VERSION=$(jq -r '.services.backend.qa' "$VERSION_FILE")

# Export versions as environment variables
export API_GATEWAY_VERSION
export FRONTEND_VERSION
export BACKEND_VERSION

echo "Using the following QA versions from version.json:"
echo "API Gateway: $API_GATEWAY_VERSION"
echo "Frontend: $FRONTEND_VERSION"
echo "Backend: $BACKEND_VERSION"

# Login to ECR (uncomment if needed)
# aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_REGISTRY

# Run docker-compose
echo "Starting the QA environment..."
docker-compose -f "$SCRIPT_DIR/docker-compose.yml" up "$@"