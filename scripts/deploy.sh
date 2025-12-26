#!/bin/bash

# ROSE TaroWorks Deployment Script
# This script deploys all components to a Salesforce org

set -e  # Exit on error

echo "========================================="
echo "ROSE TaroWorks Deployment Script"
echo "========================================="
echo ""

# Check if Salesforce CLI is installed
if ! command -v sf &> /dev/null; then
    echo "ERROR: Salesforce CLI is not installed."
    echo "Please install it from: https://developer.salesforce.com/tools/salesforcecli"
    exit 1
fi

echo "✓ Salesforce CLI found"
echo ""

# Check org authorization
echo "Checking org authorization..."
if ! sf org display &> /dev/null; then
    echo "ERROR: No default org is authorized."
    echo "Please authorize an org with: sf org login web"
    exit 1
fi

echo "✓ Org authorized"
echo ""

# Deploy metadata in dependency order
echo "Starting deployment..."
echo ""

# Step 1: Deploy custom objects
echo "1/5 Deploying custom objects..."
sf project deploy start --metadata-dir force-app/main/default/objects --wait 10
echo "✓ Custom objects deployed"
echo ""

# Step 2: Deploy Apex classes
echo "2/5 Deploying Apex classes..."
sf project deploy start --metadata-dir force-app/main/default/classes --wait 10
echo "✓ Apex classes deployed"
echo ""

# Step 3: Run Apex tests
echo "3/5 Running Apex tests..."
sf apex run test --wait 10 --result-format human --code-coverage --test-level RunLocalTests
echo "✓ Apex tests completed"
echo ""

# Step 4: Deploy Lightning Web Components
echo "4/5 Deploying Lightning Web Components..."
sf project deploy start --metadata-dir force-app/main/default/lwc --wait 10
echo "✓ LWC components deployed"
echo ""

# Step 5: Deploy profiles and sharing rules
echo "5/5 Deploying security configuration..."
sf project deploy start --metadata-dir force-app/main/default/profiles --wait 10
sf project deploy start --metadata-dir force-app/main/default/sharingRules --wait 10
echo "✓ Security configuration deployed"
echo ""

echo "========================================="
echo "Deployment completed successfully!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Create Field User records linked to your users"
echo "2. Create Form Definitions and Form Fields"
echo "3. Create Jobs and Tasks for field workers"
echo "4. Configure Experience Cloud (Community) for mobile access"
echo "5. Run setup-sample-data.sh to create test data (optional)"
echo ""
echo "See docs/DEPLOYMENT_GUIDE.md for detailed instructions."
