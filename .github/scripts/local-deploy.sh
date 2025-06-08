#!/bin/bash

# Local Infrastructure Deployment Script
# Usage: ./local-deploy.sh [environment] [action]

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
TERRAFORM_DIR="${ROOT_DIR}/terraform"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="development"
ACTION="plan"

# Parse arguments
if [[ $# -ge 1 ]]; then
    ENVIRONMENT="$1"
fi

if [[ $# -ge 2 ]]; then
    ACTION="$2"
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(development|staging|production)$ ]]; then
    echo -e "${RED}❌ Invalid environment: $ENVIRONMENT${NC}"
    echo "Valid environments: development, staging, production"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy|init|validate)$ ]]; then
    echo -e "${RED}❌ Invalid action: $ACTION${NC}"
    echo "Valid actions: plan, apply, destroy, init, validate"
    exit 1
fi

# Function to print step headers
print_step() {
    echo -e "\n${BLUE}🔧 $1${NC}"
    echo "================================"
}

# Function to check prerequisites
check_prerequisites() {
    print_step "Checking Prerequisites"
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}❌ Terraform is not installed${NC}"
        echo "Install it from: https://www.terraform.io/downloads.html"
        exit 1
    fi
    
    # Check if gcloud is installed
    if ! command -v gcloud &> /dev/null; then
        echo -e "${RED}❌ Google Cloud SDK is not installed${NC}"
        echo "Install it from: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi
    
    # Check if authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 &> /dev/null; then
        echo -e "${RED}❌ Not authenticated with Google Cloud${NC}"
        echo "Run: gcloud auth login"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites met${NC}"
}

# Function to set environment variables
set_environment_variables() {
    print_step "Setting Environment Variables for $ENVIRONMENT"
    
    case "$ENVIRONMENT" in
        "production")
            export TF_VAR_environment="production"
            export TF_VAR_project_id="pinky-promise-app"
            export TF_STATE_BUCKET="pinky-promise-app-terraform-state-$(date +%s)"
            export TF_STATE_PREFIX="terraform/production"
            ;;
        "staging")
            export TF_VAR_environment="staging"
            export TF_VAR_project_id="pinky-promise-staging"
            export TF_STATE_BUCKET="pinky-promise-staging-terraform-state"
            export TF_STATE_PREFIX="terraform/staging"
            ;;
        "development")
            export TF_VAR_environment="development"
            export TF_VAR_project_id="pinky-promise-dev"
            export TF_STATE_BUCKET="pinky-promise-dev-terraform-state"
            export TF_STATE_PREFIX="terraform/development"
            ;;
    esac
    
    # Set common variables
    export TF_VAR_alert_email="${ALERT_EMAIL:-admin@example.com}"
    
    echo -e "${GREEN}✅ Environment variables set for $ENVIRONMENT${NC}"
    echo "   Project ID: $TF_VAR_project_id"
    echo "   State Bucket: $TF_STATE_BUCKET"
}

# Function to create state bucket if it doesn't exist
ensure_state_bucket() {
    print_step "Ensuring State Bucket Exists"
    
    if ! gsutil ls gs://$TF_STATE_BUCKET &> /dev/null; then
        echo "Creating state bucket: $TF_STATE_BUCKET"
        gsutil mb gs://$TF_STATE_BUCKET
        gsutil versioning set on gs://$TF_STATE_BUCKET
        echo -e "${GREEN}✅ State bucket created${NC}"
    else
        echo -e "${GREEN}✅ State bucket already exists${NC}"
    fi
}

# Function to initialize terraform
tf_init() {
    print_step "Initializing Terraform"
    
    cd "$TERRAFORM_DIR"
    
    terraform init \
        -backend-config="bucket=$TF_STATE_BUCKET" \
        -backend-config="prefix=$TF_STATE_PREFIX" \
        -upgrade
    
    echo -e "${GREEN}✅ Terraform initialized${NC}"
}

# Function to validate terraform
tf_validate() {
    print_step "Validating Terraform Configuration"
    
    cd "$TERRAFORM_DIR"
    
    # Format check
    if ! terraform fmt -check -recursive .; then
        echo -e "${YELLOW}⚠️ Formatting issues found. Auto-fixing...${NC}"
        terraform fmt -recursive .
    fi
    
    # Validate
    terraform validate
    
    echo -e "${GREEN}✅ Terraform configuration is valid${NC}"
}

# Function to plan terraform
tf_plan() {
    print_step "Creating Terraform Plan for $ENVIRONMENT"
    
    cd "$TERRAFORM_DIR"
    
    terraform plan \
        -detailed-exitcode \
        -out="tfplan-$ENVIRONMENT" \
        -var-file="environments/$ENVIRONMENT.tfvars"
    
    PLAN_EXIT_CODE=$?
    
    if [[ $PLAN_EXIT_CODE -eq 0 ]]; then
        echo -e "${GREEN}✅ No changes detected${NC}"
    elif [[ $PLAN_EXIT_CODE -eq 2 ]]; then
        echo -e "${YELLOW}📝 Changes detected - plan saved to tfplan-$ENVIRONMENT${NC}"
    else
        echo -e "${RED}❌ Plan failed${NC}"
        exit $PLAN_EXIT_CODE
    fi
}

# Function to apply terraform
tf_apply() {
    print_step "Applying Terraform Plan for $ENVIRONMENT"
    
    cd "$TERRAFORM_DIR"
    
    # Check if plan file exists
    if [[ ! -f "tfplan-$ENVIRONMENT" ]]; then
        echo -e "${YELLOW}⚠️ No plan file found. Creating plan first...${NC}"
        tf_plan
    fi
    
    # Confirm apply for production
    if [[ "$ENVIRONMENT" == "production" ]]; then
        echo -e "${YELLOW}⚠️ WARNING: You are about to apply changes to PRODUCTION!${NC}"
        read -p "Are you sure you want to continue? (yes/no): " confirm
        if [[ "$confirm" != "yes" ]]; then
            echo "Aborted."
            exit 1
        fi
    fi
    
    terraform apply "tfplan-$ENVIRONMENT"
    
    echo -e "${GREEN}✅ Infrastructure deployed successfully${NC}"
    
    # Show outputs
    echo -e "\n${BLUE}📊 Infrastructure Outputs:${NC}"
    terraform output
}

# Function to destroy terraform
tf_destroy() {
    print_step "Destroying Infrastructure for $ENVIRONMENT"
    
    cd "$TERRAFORM_DIR"
    
    # Confirm destroy
    echo -e "${RED}⚠️ WARNING: This will DESTROY all infrastructure in $ENVIRONMENT!${NC}"
    read -p "Type 'destroy' to confirm: " confirm
    if [[ "$confirm" != "destroy" ]]; then
        echo "Aborted."
        exit 1
    fi
    
    terraform destroy \
        -auto-approve \
        -var-file="environments/$ENVIRONMENT.tfvars"
    
    echo -e "${GREEN}✅ Infrastructure destroyed${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🏗️ Local Infrastructure Deployment${NC}"
    echo "Environment: $ENVIRONMENT"
    echo "Action: $ACTION"
    echo ""
    
    check_prerequisites
    set_environment_variables
    
    case "$ACTION" in
        "init")
            ensure_state_bucket
            tf_init
            ;;
        "validate")
            tf_init
            tf_validate
            ;;
        "plan")
            ensure_state_bucket
            tf_init
            tf_validate
            tf_plan
            ;;
        "apply")
            ensure_state_bucket
            tf_init
            tf_validate
            tf_apply
            ;;
        "destroy")
            tf_init
            tf_destroy
            ;;
    esac
    
    echo -e "\n${GREEN}🎉 Operation completed successfully!${NC}"
}

# Run main function
main "$@"

