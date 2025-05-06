#!/bin/bash
# version-promotion.sh
# Script to promote service versions between environments (QA -> UAT -> Prod)

set -e

# Check required arguments
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <service-name> <source-env> [target-env]"
  echo "Example: $0 product-service qa uat"
  exit 1
fi

SERVICE_NAME=$1
SOURCE_ENV=$2
TARGET_ENV=${3:-""}

# Validate environments
VALID_ENVS=("qa" "uat" "prod")
if [[ ! " ${VALID_ENVS[@]} " =~ " ${SOURCE_ENV} " ]]; then
  echo "Error: Source environment must be one of: ${VALID_ENVS[*]}"
  exit 1
fi

# If target environment is not specified, determine it based on source
if [ -z "$TARGET_ENV" ]; then
  case $SOURCE_ENV in
    qa)
      TARGET_ENV="uat"
      ;;
    uat)
      TARGET_ENV="prod"
      ;;
    *)
      echo "Error: Cannot determine target environment from source '$SOURCE_ENV'"
      exit 1
      ;;
  esac
fi

# Validate target environment
if [[ ! " ${VALID_ENVS[@]} " =~ " ${TARGET_ENV} " ]]; then
  echo "Error: Target environment must be one of: ${VALID_ENVS[*]}"
  exit 1
fi

# Check promotion path is valid
if [[ "$SOURCE_ENV" == "qa" && "$TARGET_ENV" == "prod" ]]; then
  echo "Error: Cannot promote directly from QA to Production. Use UAT as intermediate step."
  exit 1
fi

if [[ "$SOURCE_ENV" == "prod" ]]; then
  echo "Error: Cannot promote from Production environment."
  exit 1
fi

if [[ "$SOURCE_ENV" == "$TARGET_ENV" ]]; then
  echo "Error: Source and target environments cannot be the same."
  exit 1
fi

echo "Promoting $SERVICE_NAME from $SOURCE_ENV to $TARGET_ENV..."

# Read version.json
if [ ! -f "version.json" ]; then
  echo "Error: version.json file not found"
  exit 1
fi

# Get current versions
SOURCE_VERSION=$(jq -r ".services.\"$SERVICE_NAME\".\"$SOURCE_ENV\"" version.json)
CURRENT_TARGET_VERSION=$(jq -r ".services.\"$SERVICE_NAME\".\"$TARGET_ENV\"" version.json)

if [ "$SOURCE_VERSION" == "null" ]; then
  echo "Error: Service '$SERVICE_NAME' not found in source environment '$SOURCE_ENV'"
  exit 1
fi

echo "Current versions:"
echo "  $SOURCE_ENV: $SOURCE_VERSION"
echo "  $TARGET_ENV: $CURRENT_TARGET_VERSION"

# Update version.json
echo "Updating version.json..."
jq ".services.\"$SERVICE_NAME\".\"$TARGET_ENV\" = \"$SOURCE_VERSION\" | .last_updated = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" version.json > version.json.new
mv version.json.new version.json

echo "Updated $TARGET_ENV version to $SOURCE_VERSION"

# Get ECR repository URLs
SOURCE_REPO="${SOURCE_ENV}-${SERVICE_NAME}"
TARGET_REPO="${TARGET_ENV}-${SERVICE_NAME}"

# Pull the source image
echo "Pulling image from $SOURCE_REPO:$SOURCE_VERSION..."
SOURCE_IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${SOURCE_REPO}:${SOURCE_VERSION}"
TARGET_IMAGE_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${TARGET_REPO}:${SOURCE_VERSION}"

# Tag and push the image to the target repository
echo "Tagging and pushing image to $TARGET_REPO:$SOURCE_VERSION..."
docker pull $SOURCE_IMAGE_URI
docker tag $SOURCE_IMAGE_URI $TARGET_IMAGE_URI
docker push $TARGET_IMAGE_URI

echo "Promotion complete!"
echo "Next steps:"
echo "1. Update Kubernetes manifests in $TARGET_ENV environment"
echo "2. Apply the changes using kubectl or ArgoCD"
echo "3. Verify the deployment in the $TARGET_ENV environment"

exit 0