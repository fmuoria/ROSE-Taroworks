#!/bin/bash

# ROSE TaroWorks Sample Data Creation Script
# This script creates sample data for testing the application

set -e

echo "========================================="
echo "ROSE TaroWorks Sample Data Setup"
echo "========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

TARGET_ORG="${1:-default}"
print_info "Creating sample data in org: $TARGET_ORG"

# Create anonymous Apex script for sample data
cat > /tmp/sample-data.apex << 'APEX'
// Create Field Users
List<Field_User__c> fieldUsers = new List<Field_User__c>();
for (Integer i = 1; i <= 5; i++) {
    fieldUsers.add(new Field_User__c(
        Name = 'Field Worker ' + i,
        Status__c = 'Active',
        Region__c = (Math.mod(i, 2) == 0) ? 'North' : 'South',
        Phone__c = '555-010' + i
    ));
}
insert fieldUsers;
System.debug('Created ' + fieldUsers.size() + ' field users');

// Create Form Definitions
List<Form_Definition__c> formDefs = new List<Form_Definition__c>();
formDefs.add(new Form_Definition__c(
    Name = 'Household Survey',
    Target_Object__c = 'Contact',
    Version__c = '1.0',
    Active__c = true,
    Description__c = 'Basic household information survey'
));
formDefs.add(new Form_Definition__c(
    Name = 'Beneficiary Registration',
    Target_Object__c = 'Contact',
    Version__c = '1.0',
    Active__c = true,
    Description__c = 'New beneficiary registration form'
));
insert formDefs;
System.debug('Created ' + formDefs.size() + ' form definitions');

// Create Form Fields for Household Survey
List<Form_Field__c> fields = new List<Form_Field__c>();
fields.add(new Form_Field__c(
    Form_Definition__c = formDefs[0].Id,
    Field_API_Name__c = 'FirstName',
    Field_Label__c = 'First Name',
    Field_Type__c = 'Text',
    Required__c = true,
    Display_Order__c = 1
));
fields.add(new Form_Field__c(
    Form_Definition__c = formDefs[0].Id,
    Field_API_Name__c = 'LastName',
    Field_Label__c = 'Last Name',
    Field_Type__c = 'Text',
    Required__c = true,
    Display_Order__c = 2
));
fields.add(new Form_Field__c(
    Form_Definition__c = formDefs[0].Id,
    Field_API_Name__c = 'Email',
    Field_Label__c = 'Email',
    Field_Type__c = 'Text',
    Required__c = false,
    Display_Order__c = 3
));
insert fields;
System.debug('Created ' + fields.size() + ' form fields');

// Create Jobs
List<Job__c> jobs = new List<Job__c>();
for (Integer i = 1; i <= 10; i++) {
    Integer userIndex = Math.mod(i, fieldUsers.size());
    jobs.add(new Job__c(
        Name = 'Job ' + i,
        Assigned_User__c = fieldUsers[userIndex].Id,
        Status__c = 'New',
        Priority__c = (Math.mod(i, 3) == 0) ? 'High' : (Math.mod(i, 3) == 1) ? 'Medium' : 'Low',
        Due_Date__c = Date.today().addDays(7 + i),
        Region__c = fieldUsers[userIndex].Region__c,
        Description__c = 'Sample job ' + i + ' for testing'
    ));
}
insert jobs;
System.debug('Created ' + jobs.size() + ' jobs');

// Create Tasks for each job
List<Task__c> tasks = new List<Task__c>();
for (Job__c job : jobs) {
    tasks.add(new Task__c(
        Name = 'View Beneficiary Info',
        Job__c = job.Id,
        Task_Type__c = 'View Data',
        Sequence_Order__c = 1,
        Status__c = 'Pending',
        Instructions__c = 'Review beneficiary information before survey'
    ));
    tasks.add(new Task__c(
        Name = 'Conduct Survey',
        Job__c = job.Id,
        Task_Type__c = 'Collect Data',
        Form_Definition__c = formDefs[0].Id,
        Sequence_Order__c = 2,
        Status__c = 'Pending',
        Instructions__c = 'Complete the household survey form'
    ));
}
insert tasks;
System.debug('Created ' + tasks.size() + ' tasks');

System.debug('Sample data creation complete!');
APEX

# Execute the Apex script
print_info "Executing Apex script to create sample data..."
sf apex run --file /tmp/sample-data.apex --target-org "$TARGET_ORG"

print_success "Sample data created successfully!"
echo ""
print_info "Created:"
echo "  - 5 Field User records"
echo "  - 2 Form Definitions with fields"
echo "  - 10 Jobs assigned to field users"
echo "  - 20 Tasks (2 per job)"
echo ""
print_info "You can now test the application with this sample data"

# Cleanup
rm /tmp/sample-data.apex
