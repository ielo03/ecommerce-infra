#!/bin/bash
# smoke-test.sh - QA Environment Smoke Test
#
# This script performs basic smoke tests on the ecommerce microservices
# deployed in the QA environment. It verifies that all services are up
# and running, and tests basic API functionality.
#
# Usage: ./smoke-test.sh [api-endpoint]
# Example: ./smoke-test.sh http://api-gateway-qa.example.com

set -e  # Exit immediately if a command exits with a non-zero status

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Default API endpoint if not provided
API_ENDPOINT=${1:-"http://localhost:8080"}
QA_NAMESPACE="qa"
TEST_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJ0ZXN0LXVzZXItaWQiLCJlbWFpbCI6InRlc3RAdGVzdC5jb20iLCJyb2xlIjoidXNlciIsImlhdCI6MTYxNjE1MTYxNn0.Hgr-OwTech-Wd3NZ0SzqWsf7K0g3mGBl7JsKcIVdcgQ"

echo -e "${YELLOW}Starting smoke tests for QA environment...${NC}"
echo -e "API Endpoint: ${API_ENDPOINT}"
echo "----------------------------------------"

# Function to test an endpoint
test_endpoint() {
    local endpoint=$1
    local method=${2:-"GET"}
    local data=${3:-""}
    local expected_status=${4:-200}
    local description=${5:-"Testing $endpoint"}
    
    echo -e "\n${YELLOW}$description${NC}"
    
    # Build curl command based on method and data
    local curl_cmd="curl -s -o /dev/null -w '%{http_code}' -X $method"
    
    # Add headers
    curl_cmd="$curl_cmd -H 'Content-Type: application/json'"
    
    # Add authorization header if not testing auth endpoints
    if [[ ! "$endpoint" =~ "/auth/" ]]; then
        curl_cmd="$curl_cmd -H 'Authorization: Bearer $TEST_TOKEN'"
    fi
    
    # Add data if provided
    if [ -n "$data" ]; then
        curl_cmd="$curl_cmd -d '$data'"
    fi
    
    # Add endpoint
    curl_cmd="$curl_cmd $API_ENDPOINT$endpoint"
    
    # Execute curl command
    echo "Executing: $curl_cmd"
    status_code=$(eval $curl_cmd)
    
    # Check status code
    if [ "$status_code" -eq "$expected_status" ]; then
        echo -e "${GREEN}✓ Success! Status code: $status_code${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed! Expected status code $expected_status but got $status_code${NC}"
        return 1
    fi
}

# Function to check if Kubernetes services are running
check_k8s_services() {
    echo -e "\n${YELLOW}Checking Kubernetes services in $QA_NAMESPACE namespace...${NC}"
    
    # List of services to check
    services=("api-gateway" "product-service" "order-service" "user-service")
    
    for service in "${services[@]}"; do
        echo -e "\nChecking $service..."
        
        # Check if service exists
        if kubectl get service $service -n $QA_NAMESPACE &> /dev/null; then
            echo -e "${GREEN}✓ Service $service exists${NC}"
            
            # Check if pods are running
            pod_status=$(kubectl get pods -n $QA_NAMESPACE -l app=$service -o jsonpath='{.items[*].status.phase}')
            if [[ "$pod_status" == *"Running"* ]]; then
                echo -e "${GREEN}✓ Pods for $service are running${NC}"
                
                # Check if service has endpoints
                endpoints=$(kubectl get endpoints $service -n $QA_NAMESPACE -o jsonpath='{.subsets[*].addresses}')
                if [ -n "$endpoints" ]; then
                    echo -e "${GREEN}✓ Service $service has endpoints${NC}"
                else
                    echo -e "${RED}✗ Service $service has no endpoints${NC}"
                    return 1
                fi
            else
                echo -e "${RED}✗ Pods for $service are not running${NC}"
                return 1
            fi
        else
            echo -e "${RED}✗ Service $service does not exist${NC}"
            return 1
        fi
    done
    
    return 0
}

# Main test sequence
main() {
    local failed=0
    
    # Check Kubernetes services if kubectl is available
    if command -v kubectl &> /dev/null; then
        if ! check_k8s_services; then
            failed=$((failed + 1))
        fi
    else
        echo -e "${YELLOW}kubectl not found, skipping Kubernetes service checks${NC}"
    fi
    
    # Test API Gateway health endpoint
    if ! test_endpoint "/health" "GET" "" 200 "Testing API Gateway health endpoint"; then
        failed=$((failed + 1))
    fi
    
    # Test Authentication
    if ! test_endpoint "/api/auth/login" "POST" '{"email":"test@example.com","password":"password123"}' 200 "Testing user login"; then
        failed=$((failed + 1))
    fi
    
    # Test Product Service
    if ! test_endpoint "/api/products" "GET" "" 200 "Testing product listing"; then
        failed=$((failed + 1))
    fi
    
    if ! test_endpoint "/api/products/featured" "GET" "" 200 "Testing featured products"; then
        failed=$((failed + 1))
    fi
    
    # Test Order Service
    if ! test_endpoint "/api/orders" "GET" "" 200 "Testing order listing"; then
        failed=$((failed + 1))
    fi
    
    # Test User Service
    if ! test_endpoint "/api/users/profile" "GET" "" 200 "Testing user profile"; then
        failed=$((failed + 1))
    fi
    
    # Create a test product
    if ! test_endpoint "/api/products" "POST" '{"name":"Test Product","description":"Test Description","price":9.99,"sku":"TEST-SKU-123","isActive":true}' 201 "Testing product creation"; then
        failed=$((failed + 1))
    fi
    
    # Create a test order
    if ! test_endpoint "/api/orders" "POST" '{"items":[{"productId":"test-product-id","quantity":1,"price":9.99}],"shippingAddress":{"street":"123 Test St","city":"Test City","state":"TS","zipCode":"12345","country":"Test Country"}}' 201 "Testing order creation"; then
        failed=$((failed + 1))
    fi
    
    # Summary
    echo -e "\n${YELLOW}Smoke Test Summary${NC}"
    echo "----------------------------------------"
    
    if [ $failed -eq 0 ]; then
        echo -e "${GREEN}All tests passed successfully!${NC}"
        exit 0
    else
        echo -e "${RED}$failed test(s) failed!${NC}"
        exit 1
    fi
}

# Run the main test sequence
main