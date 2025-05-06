#!/bin/bash
# switch-traffic.sh
#
# NOTE: This script is maintained for legacy purposes.
# The preferred method for blue/green deployment is now using Ansible playbooks.
# See ecommerce-infra/ansible/playbooks/blue_green_switch.yml for the Ansible implementation.

SERVICE_NAME=$1
TARGET_COLOR=$2
NAMESPACE=$3

# Validate inputs
if [ -z "$SERVICE_NAME" ] || [ -z "$TARGET_COLOR" ] || [ -z "$NAMESPACE" ]; then
  echo "Usage: $0 <service-name> <target-color> <namespace>"
  exit 1
fi

# Verify target color is valid
if [ "$TARGET_COLOR" != "blue" ] && [ "$TARGET_COLOR" != "green" ]; then
  echo "Error: target-color must be 'blue' or 'green'"
  exit 1
fi

# Get current active color
CURRENT_COLOR=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.selector.version}')
echo "Current active color for $SERVICE_NAME: $CURRENT_COLOR"

if [ "$CURRENT_COLOR" == "$TARGET_COLOR" ]; then
  echo "$TARGET_COLOR is already active for $SERVICE_NAME"
  exit 0
fi

# Update service selector to point to target color
kubectl patch service $SERVICE_NAME -n $NAMESPACE -p "{\"spec\":{\"selector\":{\"version\":\"$TARGET_COLOR\"}}}"

# Update annotation to track active version
kubectl annotate service $SERVICE_NAME -n $NAMESPACE service.kubernetes.io/active-version=$TARGET_COLOR --overwrite

# Update ConfigMap
kubectl patch configmap blue-green-config -n $NAMESPACE -p "{\"data\":{\"$SERVICE_NAME\":\"$TARGET_COLOR\"}}"

echo "Successfully switched $SERVICE_NAME traffic to $TARGET_COLOR deployment"