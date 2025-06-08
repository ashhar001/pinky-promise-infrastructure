#!/bin/bash

# Script to check for existing resources and handle conflicts
set -euo pipefail

ENVIRONMENT="${1:-production}"
PROJECT_ID="${2:-}"

if [ -z "$PROJECT_ID" ]; then
    echo "❌ PROJECT_ID not provided"
    echo "Usage: $0 <environment> <project_id>"
    exit 1
fi

echo "🔍 Checking for existing resources in project: $PROJECT_ID"
echo "Environment: $ENVIRONMENT"
echo ""

# Check for existing VPC
VPC_NAME="${ENVIRONMENT}-pinky-promise-vpc"
echo "Checking for VPC: $VPC_NAME"

if gcloud compute networks describe "$VPC_NAME" --project="$PROJECT_ID" --format="value(name)" 2>/dev/null; then
    echo "⚠️  VPC $VPC_NAME already exists"
    echo "Do you want to:"
    echo "1) Import existing VPC into Terraform state"
    echo "2) Delete existing VPC (DESTRUCTIVE)"
    echo "3) Exit and handle manually"
    read -p "Choose option [1-3]: " choice
    
    case $choice in
        1)
            echo "📥 Importing existing VPC into Terraform state..."
            cd terraform
            terraform import module.networking.google_compute_network.vpc "projects/$PROJECT_ID/global/networks/$VPC_NAME"
            echo "✅ VPC imported successfully"
            ;;
        2)
            echo "🗑️  Deleting existing VPC..."
            gcloud compute networks delete "$VPC_NAME" --project="$PROJECT_ID" --quiet
            echo "✅ VPC deleted successfully"
            ;;
        3)
            echo "🚪 Exiting. Please handle the VPC conflict manually."
            exit 1
            ;;
        *)
            echo "❌ Invalid option. Exiting."
            exit 1
            ;;
    esac
else
    echo "✅ No existing VPC found"
fi

echo ""
echo "✅ Resource check completed"
echo "If any resources exist, make sure to import them before running terraform apply"

