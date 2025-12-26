#!/bin/bash

# ROSE TaroWorks Sample Data Setup Script
# Creates sample data for testing and demonstration

set -e  # Exit on error

echo "========================================="
echo "ROSE TaroWorks Sample Data Setup"
echo "========================================="
echo ""

# Check if Salesforce CLI is installed
if ! command -v sf &> /dev/null; then
    echo "ERROR: Salesforce CLI is not installed."
    exit 1
fi

echo "Creating sample data..."
echo ""

# Create sample Field Users
echo "1/5 Creating Field Users..."
sf data create record --sobject ROSE_Field_User__c --values "Name='John Doe' Status__c='Active' Region__c='North' Phone__c='+1234567890'"
sf data create record --sobject ROSE_Field_User__c --values "Name='Jane Smith' Status__c='Active' Region__c='South' Phone__c='+1234567891'"
sf data create record --sobject ROSE_Field_User__c --values "Name='Bob Johnson' Status__c='Active' Region__c='East' Phone__c='+1234567892'"
echo "✓ Field Users created"
echo ""

# Create Form Definition
echo "2/5 Creating Form Definitions..."
FORM_ID=$(sf data create record --sobject ROSE_Form_Definition__c --values "Name='Household Survey' Target_Object__c='Contact' Version__c=1.0 Active__c=true" --json | jq -r '.result.id')
echo "✓ Form Definition created: $FORM_ID"
echo ""

# Create Form Fields
echo "3/5 Creating Form Fields..."
sf data create record --sobject ROSE_Form_Field__c --values "ROSE_Form_Definition__c='$FORM_ID' Field_API_Name__c='FirstName' Field_Label__c='First Name' Field_Type__c='Text' Required__c=true Display_Order__c=1"
sf data create record --sobject ROSE_Form_Field__c --values "ROSE_Form_Definition__c='$FORM_ID' Field_API_Name__c='LastName' Field_Label__c='Last Name' Field_Type__c='Text' Required__c=true Display_Order__c=2"
sf data create record --sobject ROSE_Form_Field__c --values "ROSE_Form_Definition__c='$FORM_ID' Field_API_Name__c='Email' Field_Label__c='Email' Field_Type__c='Text' Required__c=false Display_Order__c=3"
echo "✓ Form Fields created"
echo ""

# Get Field User ID
USER_ID=$(sf data query --query "SELECT Id FROM ROSE_Field_User__c WHERE Name='John Doe' LIMIT 1" --json | jq -r '.result.records[0].Id')

# Create sample Jobs
echo "4/5 Creating Jobs..."
JOB1=$(sf data create record --sobject ROSE_Job__c --values "Name='Community Survey - District 1' Assigned_User__c='$USER_ID' Status__c='New' Priority__c='High' Region__c='North'" --json | jq -r '.result.id')
JOB2=$(sf data create record --sobject ROSE_Job__c --values "Name='Service Delivery - Area A' Assigned_User__c='$USER_ID' Status__c='New' Priority__c='Medium' Region__c='North'" --json | jq -r '.result.id')
echo "✓ Jobs created"
echo ""

# Create sample Tasks
echo "5/5 Creating Tasks..."
sf data create record --sobject ROSE_Task__c --values "ROSE_Job__c='$JOB1' Name='Collect household data' Task_Type__c='Collect Data' ROSE_Form_Definition__c='$FORM_ID' Sequence_Order__c=1 Status__c='Pending'"
sf data create record --sobject ROSE_Task__c --values "ROSE_Job__c='$JOB1' Name='Review instructions' Task_Type__c='View Resource' Sequence_Order__c=0 Status__c='Pending'"
echo "✓ Tasks created"
echo ""

echo "========================================="
echo "Sample data created successfully!"
echo "========================================="
echo ""
echo "You can now:"
echo "1. Login as a Field User"
echo "2. View assigned jobs"
echo "3. Complete tasks"
echo "4. Test the sync functionality"
