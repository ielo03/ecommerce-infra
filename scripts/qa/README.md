# QA Environment Smoke Tests

This directory contains scripts for running smoke tests in the QA environment to verify that all services are functioning correctly after deployment.

## Smoke Test Script

The `smoke-test.sh` script performs basic tests on all microservices in the QA environment to ensure they are up and running and responding correctly to API requests.

### Features

- Tests all microservices (product-service, order-service, user-service, api-gateway)
- Verifies Kubernetes services and pods are running
- Tests basic API endpoints for each service
- Tests authentication
- Tests CRUD operations
- Provides clear output with color-coded success/failure indicators
- Returns non-zero exit code on failure for CI/CD integration

### Usage

```bash
./smoke-test.sh [api-endpoint]
```

#### Parameters

- `api-endpoint`: (Optional) The base URL of the API Gateway. Defaults to `http://localhost:8080` if not provided.

#### Examples

```bash
# Test against local environment
./smoke-test.sh

# Test against QA environment
./smoke-test.sh http://api-gateway.qa.example.com

# Test against specific endpoint
./smoke-test.sh http://10.0.0.123
```

### Integration with GitHub Actions

The smoke test script is automatically run as part of the QA deployment pipeline through the GitHub Actions workflow defined in `github-actions/workflows/qa-smoke-test.yaml`.

The workflow:

1. Runs automatically after successful deployment to QA
2. Can also be triggered manually
3. Sets up kubectl and AWS credentials
4. Determines the API Gateway endpoint
5. Runs the smoke tests
6. Sends notifications on success or failure

### Adding New Tests

To add new tests to the smoke test script:

1. Open `smoke-test.sh`
2. Add new test cases in the `main()` function using the `test_endpoint()` function
3. Follow the existing pattern for consistency

Example:

```bash
# Test a new endpoint
if ! test_endpoint "/api/new-feature" "GET" "" 200 "Testing new feature"; then
    failed=$((failed + 1))
fi
```

### Troubleshooting

If the smoke tests fail:

1. Check the GitHub Actions logs for detailed error messages
2. Verify that all services are deployed correctly
3. Check the Kubernetes logs for any errors
4. Verify that the API Gateway is accessible from the GitHub Actions runner
5. Check that the test token is valid and has the necessary permissions
