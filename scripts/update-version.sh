#!/bin/bash
# Script to update the version.json file when promoting services between environments

set -e

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Function to display usage information
function show_usage() {
    echo "Usage: $0 <service> <source-env> <target-env> [version]"
    echo "Example: $0 product-service qa uat"
    echo "Example: $0 product-service uat prod 1.0.1"
    echo
    echo "Available services: product-service, order-service, user-service, api-gateway"
    echo "Available environments: qa, uat, prod"
    exit 1
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Please install jq."
    exit 1
fi

# Check arguments
if [ "$#" -lt 3 ]; then
    show_usage
fi

SERVICE=$1
SOURCE_ENV=$2
TARGET_ENV=$3
VERSION=$4

# Validate service
VALID_SERVICES=("product-service" "order-service" "user-service" "api-gateway")
if [[ ! " ${VALID_SERVICES[@]} " =~ " ${SERVICE} " ]]; then
    echo "Error: Invalid service '${SERVICE}'. Valid services are: ${VALID_SERVICES[*]}"
    exit 1
fi

# Validate environments
VALID_ENVS=("qa" "uat" "prod")
if [[ ! " ${VALID_ENVS[@]} " =~ " ${SOURCE_ENV} " ]]; then
    echo "Error: Invalid source environment '${SOURCE_ENV}'. Valid environments are: ${VALID_ENVS[*]}"
    exit 1
fi

if [[ ! " ${VALID_ENVS[@]} " =~ " ${TARGET_ENV} " ]]; then
    echo "Error: Invalid target environment '${TARGET_ENV}'. Valid environments are: ${VALID_ENVS[*]}"
    exit 1
fi

# Check if source and target are the same
if [ "$SOURCE_ENV" == "$TARGET_ENV" ]; then
    echo "Error: Source and target environments cannot be the same."
    exit 1
fi

# Check if promotion path is valid
if [[ "$SOURCE_ENV" == "qa" && "$TARGET_ENV" == "prod" ]]; then
    echo "Error: Cannot promote directly from QA to Production. Use UAT as intermediate step."
    exit 1
fi

if [[ "$SOURCE_ENV" == "prod" ]]; then
    echo "Error: Cannot promote from Production environment."
    exit 1
fi

# Path to version.json file
VERSION_FILE="${REPO_ROOT}/version.json"

# Check if version.json exists
if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: version.json file not found at $VERSION_FILE"
    exit 1
fi

# Get current versions
SOURCE_VERSION=$(jq -r ".services.\"$SERVICE\".\"$SOURCE_ENV\"" "$VERSION_FILE")
CURRENT_TARGET_VERSION=$(jq -r ".services.\"$SERVICE\".\"$TARGET_ENV\"" "$VERSION_FILE")

if [ "$SOURCE_VERSION" == "null" ]; then
    echo "Error: Service '$SERVICE' not found in source environment '$SOURCE_ENV'"
    exit 1
fi

echo "Current versions:"
echo "  $SOURCE_ENV: $SOURCE_VERSION"
echo "  $TARGET_ENV: $CURRENT_TARGET_VERSION"

# If version is not specified, use the source version
if [ -z "$VERSION" ]; then
    VERSION=$SOURCE_VERSION
    echo "Using source version: $VERSION"
else
    echo "Using specified version: $VERSION"
fi

# Update version.json
echo "Updating version.json..."
jq ".services.\"$SERVICE\".\"$TARGET_ENV\" = \"$VERSION\" | .last_updated = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "$VERSION_FILE" > "$VERSION_FILE.new"
mv "$VERSION_FILE.new" "$VERSION_FILE"

echo "Updated $TARGET_ENV version to $VERSION"

# Reset verification status
jq ".services.\"$SERVICE\".\"${TARGET_ENV}_verified\" = false" "$VERSION_FILE" > "$VERSION_FILE.new"
mv "$VERSION_FILE.new" "$VERSION_FILE"

echo "Reset ${TARGET_ENV}_verified status to false"

echo "Version update completed successfully!"
echo "Next steps:"
echo "1. Commit and push the updated version.json file"
echo "2. The version-watcher workflow will detect the change and trigger the appropriate deployment"