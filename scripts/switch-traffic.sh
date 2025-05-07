#!/bin/bash
# Script to switch traffic between blue and green deployments

set -e

# Function to display usage information
function show_usage() {
    echo "Usage: $0 <service> <environment> <target-version>"
    echo "Example: $0 product-service qa blue"
    echo "Example: $0 product-service uat green"
    echo
    echo "Available services: product-service, order-service, user-service, api-gateway"
    echo "Available environments: qa, uat, prod"
    echo "Available target versions: blue, green"
    exit 1
}

# Check arguments
if [ "$#" -ne 3 ]; then
    show_usage
fi

SERVICE=$1
ENVIRONMENT=$2
TARGET_VERSION=$3

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

# Validate target version
VALID_VERSIONS=("blue" "green")
if [[ ! " ${VALID_VERSIONS[@]} " =~ " ${TARGET_VERSION} " ]]; then
    echo "Error: Invalid target version '${TARGET_VERSION}'. Valid target versions are: ${VALID_VERSIONS[*]}"
    exit 1
fi

# Get the current active version
CURRENT_VERSION=$(kubectl get service ${SERVICE} -n ecommerce-${ENVIRONMENT} -o jsonpath='{.metadata.annotations.service\.kubernetes\.io/active-version}')

if [ -z "$CURRENT_VERSION" ]; then
    echo "Error: Could not determine current active version for service '${SERVICE}' in environment '${ENVIRONMENT}'."
    exit 1
fi

echo "Current active version: ${CURRENT_VERSION}"
echo "Target version: ${TARGET_VERSION}"

if [ "$CURRENT_VERSION" == "$TARGET_VERSION" ]; then
    echo "Service '${SERVICE}' in environment '${ENVIRONMENT}' is already using version '${TARGET_VERSION}'."
    exit 0
fi

# Check if the target version is ready
READY_REPLICAS=$(kubectl get deployment ${SERVICE}-${TARGET_VERSION} -n ecommerce-${ENVIRONMENT} -o jsonpath='{.status.readyReplicas}')
TOTAL_REPLICAS=$(kubectl get deployment ${SERVICE}-${TARGET_VERSION} -n ecommerce-${ENVIRONMENT} -o jsonpath='{.spec.replicas}')

if [ -z "$READY_REPLICAS" ] || [ "$READY_REPLICAS" -lt "$TOTAL_REPLICAS" ]; then
    echo "Warning: Target version '${TARGET_VERSION}' is not fully ready. Ready replicas: ${READY_REPLICAS}/${TOTAL_REPLICAS}"
    echo -n "Do you want to continue anyway? (y/n): "
    read confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Traffic switch cancelled."
        exit 1
    fi
fi

# Update the service selector
echo "Updating service selector to target version '${TARGET_VERSION}'..."
kubectl patch service ${SERVICE} -n ecommerce-${ENVIRONMENT} --type=json -p "[{\"op\": \"replace\", \"path\": \"/spec/selector/version\", \"value\": \"${TARGET_VERSION}\"}]"

# Update the service annotation
echo "Updating service annotation to reflect the active version..."
kubectl patch service ${SERVICE} -n ecommerce-${ENVIRONMENT} --type=json -p "[{\"op\": \"replace\", \"path\": \"/metadata/annotations/service.kubernetes.io~1active-version\", \"value\": \"${TARGET_VERSION}\"}]"

echo "Traffic switched successfully from '${CURRENT_VERSION}' to '${TARGET_VERSION}' for service '${SERVICE}' in environment '${ENVIRONMENT}'."

# Update version.json file if needed
echo -n "Do you want to update the version.json file to reflect this change? (y/n): "
read update_version
if [[ "$update_version" == "y" || "$update_version" == "Y" ]]; then
    # Get the directory of the script
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Update the version.json file
    echo "Updating version.json file..."
    ${SCRIPT_DIR}/update-version-status.sh ${SERVICE} ${ENVIRONMENT} ${TARGET_VERSION}
fi

echo "Done."