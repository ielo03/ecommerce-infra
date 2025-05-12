#!/bin/bash
# run-smoketest.sh - Simple Smoke Test for Ecommerce Microservices
#
# This script performs basic smoke tests on the ecommerce microservices
# to verify successful deployment of new images.
#
# Usage: ./run-smoketest.sh [ip-address]
# Example: ./run-smoketest.sh 10.0.0.1
# Example: ./run-smoketest.sh qa-environment.example.com

set -e  # Exit immediately if a command exits with a non-zero status

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get IP address from command line argument
if [ -z "$1" ]; then
  echo -e "${RED}Error: No IP address provided${NC}"
  echo -e "Usage: ./run-smoketest.sh [ip-address]"
  echo -e "Example: ./run-smoketest.sh 10.0.0.1"
  echo -e "Example: ./run-smoketest.sh qa-environment.example.com"
  exit 1
fi

IP_ADDRESS="$1"

# Validate IP address is not localhost
if [ "$IP_ADDRESS" == "localhost" ] || [ "$IP_ADDRESS" == "127.0.0.1" ]; then
  echo -e "${RED}Error: localhost is not a valid target for smoke tests${NC}"
  echo -e "Please provide an EC2 instance IP address or hostname"
  exit 1
fi

BASE_URL="http://${IP_ADDRESS}:8080"

echo -e "${YELLOW}Starting smoke tests for deployment at ${IP_ADDRESS}...${NC}"
echo -e "Base URL: ${BASE_URL}"
echo "----------------------------------------"

# Function to test an endpoint
test_endpoint() {
    local endpoint=$1
    local method=${2:-"GET"}
    local expected_status=${3:-200}
    local description=${4:-"Testing $endpoint"}
    
    echo -e "\n${YELLOW}$description${NC}"
    
    # Build curl command
    local curl_cmd="curl -s -o response.json -w '%{http_code}' -X $method ${BASE_URL}${endpoint}"
    
    # Execute curl command
    echo "Executing: $curl_cmd"
    status_code=$(eval $curl_cmd)
    
    # Check status code
    if [ "$status_code" -eq "$expected_status" ]; then
        echo -e "${GREEN}✓ Success! Status code: $status_code${NC}"
        
        # Print response for debugging
        echo "Response:"
        cat response.json | grep -v "^$" | head -20
        if [ $(cat response.json | wc -l) -gt 20 ]; then
            echo "... (response truncated)"
        fi
        
        return 0
    else
        echo -e "${RED}✗ Failed! Expected status code $expected_status but got $status_code${NC}"
        
        # Print response for debugging
        echo "Error response:"
        cat response.json
        
        return 1
    fi
}

# Main test sequence
main() {
    local failed=0
    
    # Test 1: API Gateway health endpoint
    if ! test_endpoint "/health" "GET" 200 "Testing API Gateway health endpoint"; then
        failed=$((failed + 1))
    fi
    
    # Test 2: Backend notes endpoint
    if ! test_endpoint "/api/notes" "GET" 200 "Testing backend notes API"; then
        failed=$((failed + 1))
    fi
    
    # Test 3: Frontend health endpoint (via API Gateway)
    if ! test_endpoint "/health" "GET" 200 "Testing frontend health (via API Gateway)"; then
        failed=$((failed + 1))
    fi
    
    # Summary
    echo -e "\n${YELLOW}Smoke Test Summary${NC}"
    echo "----------------------------------------"
    
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}All tests passed successfully!${NC}"
        echo -e "${GREEN}Deployment verification complete.${NC}"
        # Clean up
        rm -f response.json
        exit 0
    else
        echo -e "${RED}$failed test(s) failed!${NC}"
        echo -e "${RED}Deployment verification failed.${NC}"
        # Clean up
        rm -f response.json
        exit 1
    fi
}

# Run the main test sequence
main