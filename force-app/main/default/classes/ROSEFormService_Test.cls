/**
 * Test class for ROSEFormService
 */
@IsTest
private class ROSEFormService_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create form definition
        ROSE_Form_Definition__c formDef = new ROSE_Form_Definition__c(
            Name = 'Contact Survey',
            Target_Object__c = 'Contact',
            Version__c = 1.0,
            Active__c = true,
            Description__c = 'Test form for contact data collection'
        );
        insert formDef;
        
        // Create form fields
        List<ROSE_Form_Field__c> fields = new List<ROSE_Form_Field__c>{
            new ROSE_Form_Field__c(
                ROSE_Form_Definition__c = formDef.Id,
                Field_API_Name__c = 'FirstName',
                Field_Label__c = 'First Name',
                Field_Type__c = 'Text',
                Required__c = true,
                Display_Order__c = 1
            ),
            new ROSE_Form_Field__c(
                ROSE_Form_Definition__c = formDef.Id,
                Field_API_Name__c = 'LastName',
                Field_Label__c = 'Last Name',
                Field_Type__c = 'Text',
                Required__c = true,
                Display_Order__c = 2
            ),
            new ROSE_Form_Field__c(
                ROSE_Form_Definition__c = formDef.Id,
                Field_API_Name__c = 'Email',
                Field_Label__c = 'Email',
                Field_Type__c = 'Text',
                Required__c = false,
                Display_Order__c = 3,
                Validation_Rule__c = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$'
            )
        };
        insert fields;
        
        // Create field user
        ROSE_Field_User__c fieldUser = new ROSE_Field_User__c(
            Name = 'Test Field User',
            Status__c = 'Active',
            Region__c = 'North'
        );
        insert fieldUser;
        
        // Create job
        ROSE_Job__c job = new ROSE_Job__c(
            Name = 'Test Job',
            Assigned_User__c = fieldUser.Id,
            Status__c = 'New',
            Priority__c = 'High'
        );
        insert job;
        
        // Create task
        ROSE_Task__c task = new ROSE_Task__c(
            ROSE_Job__c = job.Id,
            Name = 'Test Task',
            Task_Type__c = 'Collect Data',
            ROSE_Form_Definition__c = formDef.Id,
            Status__c = 'Pending'
        );
        insert task;
    }
    
    @IsTest
    static void testGetActiveFormDefinitions() {
        Test.startTest();
        List<ROSE_Form_Definition__c> forms = ROSEFormService.getActiveFormDefinitions();
        Test.stopTest();
        
        System.assertNotEquals(null, forms, 'Forms should not be null');
        System.assertEquals(1, forms.size(), 'Should have 1 active form');
        System.assertEquals('Contact Survey', forms[0].Name, 'Form name should match');
        System.assertEquals('Contact', forms[0].Target_Object__c, 'Target object should match');
    }
    
    @IsTest
    static void testGetFormFields() {
        ROSE_Form_Definition__c formDef = [SELECT Id FROM ROSE_Form_Definition__c LIMIT 1];
        
        Test.startTest();
        List<ROSE_Form_Field__c> fields = ROSEFormService.getFormFields(formDef.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, fields, 'Fields should not be null');
        System.assertEquals(3, fields.size(), 'Should have 3 fields');
        System.assertEquals('FirstName', fields[0].Field_API_Name__c, 'First field should be FirstName');
        System.assertEquals(true, fields[0].Required__c, 'FirstName should be required');
    }
    
    @IsTest
    static void testGetFormFieldsNullId() {
        try {
            Test.startTest();
            ROSEFormService.getFormFields(null);
            Test.stopTest();
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(true, 'Exception expected for null ID');
        }
    }
    
    @IsTest
    static void testProcessFormResponseCreate() {
        ROSE_Form_Definition__c formDef = [SELECT Id FROM ROSE_Form_Definition__c LIMIT 1];
        ROSE_Task__c task = [SELECT Id FROM ROSE_Task__c LIMIT 1];
        
        // Create form response
        Map<String, Object> responseData = new Map<String, Object>{
            'FirstName' => 'John',
            'LastName' => 'Doe',
            'Email' => 'john.doe@example.com'
        };
        
        ROSE_Form_Response__c response = new ROSE_Form_Response__c(
            ROSE_Task__c = task.Id,
            ROSE_Form_Definition__c = formDef.Id,
            Response_Data__c = JSON.serialize(responseData),
            Submitted_Date__c = DateTime.now()
        );
        insert response;
        
        Test.startTest();
        Id contactId = ROSEFormService.processFormResponse(response);
        Test.stopTest();
        
        System.assertNotEquals(null, contactId, 'Contact ID should not be null');
        
        // Verify contact was created
        Contact contact = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE Id = :contactId];
        System.assertEquals('John', contact.FirstName, 'First name should match');
        System.assertEquals('Doe', contact.LastName, 'Last name should match');
        System.assertEquals('john.doe@example.com', contact.Email, 'Email should match');
    }
    
    @IsTest
    static void testProcessFormResponseUpdate() {
        ROSE_Form_Definition__c formDef = [SELECT Id FROM ROSE_Form_Definition__c LIMIT 1];
        ROSE_Task__c task = [SELECT Id FROM ROSE_Task__c LIMIT 1];
        
        // Create existing contact
        Contact existingContact = new Contact(FirstName = 'Jane', LastName = 'Smith');
        insert existingContact;
        
        // Create form response to update
        Map<String, Object> responseData = new Map<String, Object>{
            'FirstName' => 'Jane',
            'LastName' => 'Smith-Updated',
            'Email' => 'jane.smith@example.com'
        };
        
        ROSE_Form_Response__c response = new ROSE_Form_Response__c(
            ROSE_Task__c = task.Id,
            ROSE_Form_Definition__c = formDef.Id,
            Response_Data__c = JSON.serialize(responseData),
            Target_Record__c = existingContact.Id,
            Submitted_Date__c = DateTime.now()
        );
        insert response;
        
        Test.startTest();
        Id contactId = ROSEFormService.processFormResponse(response);
        Test.stopTest();
        
        System.assertEquals(existingContact.Id, contactId, 'Contact ID should match existing');
        
        // Verify contact was updated
        Contact contact = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE Id = :contactId];
        System.assertEquals('Smith-Updated', contact.LastName, 'Last name should be updated');
        System.assertEquals('jane.smith@example.com', contact.Email, 'Email should be updated');
    }
    
    @IsTest
    static void testValidateFormResponse() {
        ROSE_Form_Definition__c formDef = [SELECT Id FROM ROSE_Form_Definition__c LIMIT 1];
        
        // Test valid data
        Map<String, Object> validData = new Map<String, Object>{
            'FirstName' => 'John',
            'LastName' => 'Doe',
            'Email' => 'john@example.com'
        };
        
        Test.startTest();
        List<String> errors = ROSEFormService.validateFormResponse(validData, formDef.Id);
        Test.stopTest();
        
        System.assertEquals(0, errors.size(), 'Should have no validation errors');
    }
    
    @IsTest
    static void testValidateFormResponseMissingRequired() {
        ROSE_Form_Definition__c formDef = [SELECT Id FROM ROSE_Form_Definition__c LIMIT 1];
        
        // Test missing required field
        Map<String, Object> invalidData = new Map<String, Object>{
            'FirstName' => 'John'
            // Missing LastName
        };
        
        Test.startTest();
        List<String> errors = ROSEFormService.validateFormResponse(invalidData, formDef.Id);
        Test.stopTest();
        
        System.assertNotEquals(0, errors.size(), 'Should have validation errors');
        System.assert(errors[0].contains('required'), 'Error should mention required field');
    }
    
    @IsTest
    static void testValidateFormResponseInvalidEmail() {
        ROSE_Form_Definition__c formDef = [SELECT Id FROM ROSE_Form_Definition__c LIMIT 1];
        
        // Test invalid email format
        Map<String, Object> invalidData = new Map<String, Object>{
            'FirstName' => 'John',
            'LastName' => 'Doe',
            'Email' => 'invalid-email'
        };
        
        Test.startTest();
        List<String> errors = ROSEFormService.validateFormResponse(invalidData, formDef.Id);
        Test.stopTest();
        
        System.assertNotEquals(0, errors.size(), 'Should have validation errors');
        System.assert(errors[0].contains('format'), 'Error should mention format issue');
    }
    
    @IsTest
    static void testBulkProcessFormResponses() {
        ROSE_Form_Definition__c formDef = [SELECT Id FROM ROSE_Form_Definition__c LIMIT 1];
        ROSE_Task__c task = [SELECT Id FROM ROSE_Task__c LIMIT 1];
        
        // Create 200 form responses
        List<ROSE_Form_Response__c> responses = new List<ROSE_Form_Response__c>();
        for (Integer i = 0; i < 200; i++) {
            Map<String, Object> responseData = new Map<String, Object>{
                'FirstName' => 'First' + i,
                'LastName' => 'Last' + i,
                'Email' => 'user' + i + '@example.com'
            };
            
            responses.add(new ROSE_Form_Response__c(
                ROSE_Task__c = task.Id,
                ROSE_Form_Definition__c = formDef.Id,
                Response_Data__c = JSON.serialize(responseData),
                Submitted_Date__c = DateTime.now()
            ));
        }
        insert responses;
        
        Test.startTest();
        List<Id> contactIds = new List<Id>();
        for (ROSE_Form_Response__c response : responses) {
            try {
                Id contactId = ROSEFormService.processFormResponse(response);
                contactIds.add(contactId);
            } catch (Exception e) {
                System.debug('Error processing response: ' + e.getMessage());
            }
        }
        Test.stopTest();
        
        System.assertNotEquals(0, contactIds.size(), 'Should have created contacts');
    }
}
