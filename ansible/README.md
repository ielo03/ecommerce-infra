# Ansible Automation for E-Commerce Infrastructure

This directory contains Ansible playbooks, roles, and inventory files for automating various aspects of the E-Commerce infrastructure deployment and management.

## Directory Structure

```
ansible/
├── ansible.cfg           # Ansible configuration
├── group_vars/           # Variables for inventory groups
│   ├── qa.yml            # QA environment variables
│   ├── uat.yml           # UAT environment variables
│   └── prod.yml          # Production environment variables
├── inventory/            # Inventory files
│   ├── qa                # QA environment inventory
│   ├── uat               # UAT environment inventory
│   └── prod              # Production environment inventory
├── playbooks/            # Playbooks
│   ├── main.yml                      # Main orchestration playbook
│   ├── ec2_configuration.yml         # EC2 instance configuration
│   ├── apply_kubernetes_manifests.yml # Apply K8s manifests
│   ├── blue_green_switch.yml         # Blue/Green deployment switch
│   └── version_promotion.yml         # Version promotion between environments
```

## Prerequisites

1. Ansible 2.9+ installed on your control machine
2. AWS CLI configured with appropriate credentials
3. SSH access to EC2 instances
4. kubectl installed and configured

## Configuration

Before running the playbooks, ensure you have:

1. Updated the inventory files with the correct host information
2. Configured the group variables for each environment
3. Set up SSH keys for accessing EC2 instances

## Usage

### Main Playbook

The main playbook orchestrates all other playbooks and can be used for most operations:

```bash
# Deploy all services to QA
ansible-playbook playbooks/main.yml -i inventory/qa -e "env=qa action_type=deploy service=all"

# Configure EC2 instances in UAT
ansible-playbook playbooks/main.yml -i inventory/uat -e "env=uat action_type=configure"

# Switch traffic to green deployment in Production
ansible-playbook playbooks/main.yml -i inventory/prod -e "env=prod action_type=switch service=product-service color=green"

# Promote product-service from QA to UAT
ansible-playbook playbooks/main.yml -e "action_type=promote service=product-service source_env=qa target_env=uat"
```

### Individual Playbooks

You can also run individual playbooks directly:

#### EC2 Configuration

```bash
ansible-playbook playbooks/ec2_configuration.yml -i inventory/qa
```

This playbook:

- Updates all packages
- Installs required software (Docker, Python, AWS CLI, kubectl)
- Configures Docker and kubectl
- Sets up the EKS configuration

#### Apply Kubernetes Manifests

```bash
ansible-playbook playbooks/apply_kubernetes_manifests.yml -i inventory/qa -e "service=product-service"
```

This playbook:

- Applies Kubernetes manifests for the specified service
- Waits for deployments to be ready
- Verifies the deployment status

#### Blue/Green Deployment Switch

```bash
ansible-playbook playbooks/blue_green_switch.yml -i inventory/qa -e "service=product-service color=green"
```

This playbook:

- Checks the current active deployment (blue or green)
- Verifies the target deployment is ready
- Switches traffic to the target deployment
- Runs smoke tests to verify the switch was successful

#### Version Promotion

```bash
ansible-playbook playbooks/version_promotion.yml -e "service=product-service source=qa target=uat"
```

This playbook:

- Pulls the Docker image from the source environment
- Tags and pushes it to the target environment
- Updates the version.json file
- Applies the Kubernetes manifests in the target environment

## Integration with CI/CD

These Ansible playbooks are designed to be integrated with the GitHub Actions CI/CD pipelines. The workflows call these playbooks to:

1. Configure EC2 instances when new infrastructure is provisioned
2. Deploy applications to the appropriate environment
3. Switch traffic in blue/green deployments
4. Promote versions between environments

## Relationship with Existing Tools

Ansible has been added to enhance the automation capabilities of this project. It works alongside:

- **Terraform**: Handles infrastructure provisioning
- **Kubernetes**: Manages container orchestration
- **GitHub Actions**: Orchestrates CI/CD workflows

While there are legacy shell scripts in the repository that perform similar functions, Ansible is now the preferred method for deployment and configuration management tasks. The GitHub Actions workflows have been updated to use Ansible exclusively.

## Troubleshooting

If you encounter issues:

1. Check the Ansible logs for detailed error messages
2. Verify SSH connectivity to the target hosts
3. Ensure AWS credentials are properly configured
4. Validate that kubectl is properly configured for the target EKS cluster

For more detailed information, refer to the main project README.
