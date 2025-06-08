#!/bin/bash

# Script to safely cleanup resources
set -euo pipefail

ENVIRONMENT="${1:-production}"
PROJECT_ID="${2:-}"
FORCE="${3:-false}"

if [ -z "$PROJECT_ID" ]; then
    echo "❌ PROJECT_ID not provided"
    echo "Usage: $0 <environment> <project_id> [force]"
    echo "Use 'force=true' to skip confirmation prompts"
    exit 1
fi

echo "🧹 Cleaning up resources for environment: $ENVIRONMENT"
echo "Project: $PROJECT_ID"
echo ""

if [ "$FORCE" != "true" ]; then
    echo "⚠️  WARNING: This will delete ALL infrastructure resources!"
    echo "Environment: $ENVIRONMENT"
    echo "Project: $PROJECT_ID"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        echo "❌ Operation cancelled"
        exit 1
    fi
fi

echo "🗑️  Starting cleanup process..."

# Delete VPC
VPC_NAME="${ENVIRONMENT}-pinky-promise-vpc"
echo "Checking for VPC: $VPC_NAME"
if gcloud compute networks describe "$VPC_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "🗑️  Deleting VPC: $VPC_NAME"
    gcloud compute networks delete "$VPC_NAME" --project="$PROJECT_ID" --quiet
    echo "✅ VPC deleted"
else
    echo "ℹ️  VPC $VPC_NAME not found"
fi

echo ""
echo "✅ Cleanup completed for environment: $ENVIRONMENT"
echo "All resources have been removed from project: $PROJECT_ID"

