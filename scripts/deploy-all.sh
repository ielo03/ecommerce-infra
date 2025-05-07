#!/bin/bash
# Main deployment script for the ecommerce platform

set -e

# Function to display a menu and get user input
function show_menu() {
    echo "===== Ecommerce Platform Deployment ====="
    echo "1) Deploy to QA environment"
    echo "2) Deploy to UAT environment"
    echo "3) Deploy to Production environment"
    echo "4) Deploy to all environments"
    echo "5) Exit"
    echo "========================================"
    echo -n "Enter your choice [1-5]: "
    read choice
    echo
    return $choice
}

# Function to confirm deployment
function confirm_deployment() {
    local env=$1
    echo -n "Are you sure you want to deploy to $env environment? (y/n): "
    read confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Deployment to $env environment cancelled."
        return 1
    fi
    return 0
}

# Function to deploy to QA environment
function deploy_qa() {
    echo "Deploying to QA environment..."
    ./deploy-qa.sh
    echo "QA deployment completed."
}

# Function to deploy to UAT environment
function deploy_uat() {
    echo "Deploying to UAT environment..."
    ./deploy-uat.sh
    echo "UAT deployment completed."
}

# Function to deploy to Production environment
function deploy_prod() {
    echo "Deploying to Production environment..."
    ./deploy-prod.sh
    echo "Production deployment completed."
}

# Main script
cd "$(dirname "$0")"

while true; do
    show_menu
    choice=$?

    case $choice in
        1)
            if confirm_deployment "QA"; then
                deploy_qa
            fi
            ;;
        2)
            if confirm_deployment "UAT"; then
                deploy_uat
            fi
            ;;
        3)
            if confirm_deployment "Production"; then
                deploy_prod
            fi
            ;;
        4)
            if confirm_deployment "all"; then
                deploy_qa
                deploy_uat
                deploy_prod
                echo "All environments deployed successfully."
            fi
            ;;
        5)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please try again."
            ;;
    esac

    echo
    echo -n "Press Enter to continue..."
    read
    clear
done