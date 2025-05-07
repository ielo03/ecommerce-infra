#!/bin/bash
# Script to update the version status in the version.json file

set -e

# Function to display usage information
function show_usage() {
    echo "Usage: $0 <service> <environment> <active-version>"
    echo "Example: $0 product-service qa blue"
    echo "Example: $0 product-service uat green"
    echo
    echo "Available services: product-service, order-service, user-service, api-gateway"
    echo "Available environments: qa, uat, prod"
    echo "Available active versions: blue, green"
    exit 1
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed. Please install jq."
    exit 1
fi

# Check arguments
if [ "$#" -ne 3 ]; then
    show_usage
fi

SERVICE=$1
ENVIRONMENT=$2
ACTIVE_VERSION=$3

# Validate service
VALID_SERVICES=("product-service" "order-service" "user-service" "api-gateway")
if [[ ! " ${VALID_SERVICES[@]} " =~ " ${SERVICE} " ]]; then
    echo "Error: Invalid service '${SERVICE}'. Valid services are: ${VALID_SERVICES[*]}"
    exit 1
fi

# Validate environment
VALID_ENVS=("qa" "uat" "prod")
if [[ ! " ${VALID_ENVS[@]} " =~ " ${ENVIRONMENT} " ]]; then
    echo "Error: Invalid environment '${ENVIRONMENT}'. Valid environments are: ${VALID_ENVS[*]}"
    exit 1
fi

# Validate active version
VALID_VERSIONS=("blue" "green")
if [[ ! " ${VALID_VERSIONS[@]} " =~ " ${ACTIVE_VERSION} " ]]; then
    echo "Error: Invalid active version '${ACTIVE_VERSION}'. Valid active versions are: ${VALID_VERSIONS[*]}"
    exit 1
fi

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Path to version.json file
VERSION_FILE="${REPO_ROOT}/version.json"

# Check if version.json exists
if [ ! -f "$VERSION_FILE" ]; then
    echo "Error: version.json file not found at $VERSION_FILE"
    exit 1
fi

# Get the current version
CURRENT_VERSION=$(jq -r ".services.\"$SERVICE\".\"$ENVIRONMENT\"" "$VERSION_FILE")

if [ "$CURRENT_VERSION" == "null" ]; then
    echo "Error: Service '$SERVICE' not found in environment '$ENVIRONMENT'"
    exit 1
fi

echo "Current version: $CURRENT_VERSION"

# Update version.json with active version
echo "Updating version.json with active version '$ACTIVE_VERSION' for service '$SERVICE' in environment '$ENVIRONMENT'..."
jq ".services.\"$SERVICE\".\"${ENVIRONMENT}_active_version\" = \"$ACTIVE_VERSION\" | .last_updated = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" "$VERSION_FILE" > "$VERSION_FILE.new"
mv "$VERSION_FILE.new" "$VERSION_FILE"

# Set verification status to true
jq ".services.\"$SERVICE\".\"${ENVIRONMENT}_verified\" = true" "$VERSION_FILE" > "$VERSION_FILE.new"
mv "$VERSION_FILE.new" "$VERSION_FILE"

echo "Version status updated successfully!"
echo "Next steps:"
echo "1. Commit and push the updated version.json file"
echo "2. The version-watcher workflow will detect the change and update the status in the monitoring dashboard"