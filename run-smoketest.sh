#!/bin/bash
# run-smoketest.sh - Simple Smoke Test for Ecommerce Microservices
#
# This script performs basic smoke tests on the ecommerce microservices
# to verify successful deployment of new images.
#
# Usage: ./run-smoketest.sh [ip-address]
# Example: ./run-smoketest.sh 10.0.0.1
# Example: ./run-smoketest.sh qa-environment.example.com

# Note: We're not using 'set -e' to allow for retries

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

# Function to sleep with countdown
sleep_with_countdown() {
    local seconds=$1
    echo -e "${YELLOW}Waiting $seconds seconds before next attempt...${NC}"
    
    while [ $seconds -gt 0 ]; do
        echo -ne "${YELLOW}$seconds seconds remaining...${NC}\r"
        sleep 1
        seconds=$((seconds - 1))
    done
    echo -e "\n${YELLOW}Retrying...${NC}"
}

# Run the main test sequence with retries
MAX_RETRIES=5
RETRY_DELAY=30
ATTEMPT=1

while [ $ATTEMPT -le $MAX_RETRIES ]; do
    echo -e "${YELLOW}Attempt $ATTEMPT of $MAX_RETRIES${NC}"
    
    # Run the test
    main
    RESULT=$?
    
    # If successful, exit with success
    if [ $RESULT -eq 0 ]; then
        echo -e "${GREEN}Smoke test passed on attempt $ATTEMPT!${NC}"
        exit 0
    fi
    
    # If we've reached the maximum retries, exit with failure
    if [ $ATTEMPT -eq $MAX_RETRIES ]; then
        echo -e "${RED}All $MAX_RETRIES attempts failed. Giving up.${NC}"
        exit 1
    fi
    
    # Otherwise, increment the attempt counter and sleep before retrying
    ATTEMPT=$((ATTEMPT + 1))
    sleep_with_countdown $RETRY_DELAY
done