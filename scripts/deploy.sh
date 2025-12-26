#!/bin/bash

# ROSE TaroWorks Deployment Script
# This script deploys the ROSE TaroWorks application to a Salesforce org

set -e

echo "========================================="
echo "ROSE TaroWorks Deployment Script"
echo "========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Check if Salesforce CLI is installed
if ! command -v sf &> /dev/null; then
    print_error "Salesforce CLI is not installed. Please install it first."
    print_info "Visit: https://developer.salesforce.com/tools/salesforcecli"
    exit 1
fi

print_success "Salesforce CLI detected"

# Check org authorization
print_info "Checking org authorization..."
if ! sf org display --target-org "${1:-default}" &> /dev/null; then
    print_error "Org is not authorized. Please authorize your org first."
    print_info "Run: sf org login web"
    exit 1
fi

print_success "Org authorization confirmed"

# Get org alias
TARGET_ORG="${1:-default}"
print_info "Deploying to org: $TARGET_ORG"

# Deploy metadata in order (objects first, then classes, then LWC)
echo ""
print_info "Phase 1: Deploying Custom Objects..."
sf project deploy start \
    --source-dir force-app/main/default/objects \
    --target-org "$TARGET_ORG" \
    --wait 10

print_success "Custom Objects deployed"

echo ""
print_info "Phase 2: Deploying Apex Classes..."
sf project deploy start \
    --source-dir force-app/main/default/classes \
    --target-org "$TARGET_ORG" \
    --wait 10

print_success "Apex Classes deployed"

echo ""
print_info "Phase 3: Deploying Lightning Web Components..."
sf project deploy start \
    --source-dir force-app/main/default/lwc \
    --target-org "$TARGET_ORG" \
    --wait 10

print_success "Lightning Web Components deployed"

echo ""
print_info "Phase 4: Running Apex Tests..."
TEST_RESULT=$(sf apex run test \
    --target-org "$TARGET_ORG" \
    --test-level RunLocalTests \
    --result-format human \
    --wait 10)

echo "$TEST_RESULT"

# Check test coverage
COVERAGE=$(echo "$TEST_RESULT" | grep "Org Wide Coverage" | awk '{print $NF}' | tr -d '%')

if [ -n "$COVERAGE" ] && [ "$COVERAGE" -ge 75 ]; then
    print_success "Test coverage: $COVERAGE% (requirement: 75%)"
else
    print_error "Test coverage too low: $COVERAGE% (requirement: 75%)"
    print_info "Please review test classes and ensure adequate coverage"
fi

echo ""
print_success "========================================="
print_success "Deployment Complete!"
print_success "========================================="
echo ""
print_info "Next Steps:"
echo "1. Run setup-sample-data.sh to create sample data"
echo "2. Configure Experience Cloud site for field workers"
echo "3. Assign ROSE Field Worker profile to users"
echo "4. Test the application on mobile devices"
echo ""
print_info "For more details, see docs/DEPLOYMENT_GUIDE.md"
