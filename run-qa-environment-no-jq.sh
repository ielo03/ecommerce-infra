#!/bin/bash

# Script to run the QA environment using versions from version.json
# This version doesn't require jq and uses grep/sed instead

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
    echo "Please check the format of the file or use the jq version of this script"
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

# Login to ECR (uncomment if needed)
# aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $ECR_REGISTRY

# Run docker-compose
echo "Starting the QA environment..."
docker-compose -f "$SCRIPT_DIR/docker-compose.yml" up "$@"