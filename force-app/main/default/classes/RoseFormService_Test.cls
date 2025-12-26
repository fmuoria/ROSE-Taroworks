/**
 * @description Test class for RoseFormService
 * @author ROSE Team
 * @date 2025
 */
@isTest
private class RoseFormService_Test {
    
    @testSetup
    static void setup() {
        // Create form definition
        Form_Definition__c formDef = new Form_Definition__c(
            Name = 'Test Form',
            Target_Object__c = 'Contact',
            Version__c = '1.0',
            Active__c = true,
            Description__c = 'Test form definition'
        );
        insert formDef;
        
        // Create form fields
        List<Form_Field__c> fields = new List<Form_Field__c>();
        
        fields.add(new Form_Field__c(
            Form_Definition__c = formDef.Id,
            Field_API_Name__c = 'FirstName',
            Field_Label__c = 'First Name',
            Field_Type__c = 'Text',
            Required__c = true,
            Display_Order__c = 1
        ));
        
        fields.add(new Form_Field__c(
            Form_Definition__c = formDef.Id,
            Field_API_Name__c = 'LastName',
            Field_Label__c = 'Last Name',
            Field_Type__c = 'Text',
            Required__c = true,
            Display_Order__c = 2
        ));
        
        fields.add(new Form_Field__c(
            Form_Definition__c = formDef.Id,
            Field_API_Name__c = 'Email',
            Field_Label__c = 'Email',
            Field_Type__c = 'Text',
            Required__c = false,
            Display_Order__c = 3
        ));
        
        insert fields;
    }
    
    @isTest
    static void testGetActiveFormDefinitions() {
        Test.startTest();
        List<Form_Definition__c> forms = RoseFormService.getActiveFormDefinitions();
        Test.stopTest();
        
        System.assertEquals(1, forms.size(), 'Should return 1 active form');
        System.assertEquals('Test Form', forms[0].Name, 'Form name should match');
    }
    
    @isTest
    static void testGetFormFields() {
        Form_Definition__c formDef = [SELECT Id FROM Form_Definition__c LIMIT 1];
        
        Test.startTest();
        List<Form_Field__c> fields = RoseFormService.getFormFields(formDef.Id);
        Test.stopTest();
        
        System.assertEquals(3, fields.size(), 'Should return 3 fields');
        System.assertEquals('FirstName', fields[0].Field_API_Name__c, 'First field should be FirstName');
    }
    
    @isTest
    static void testGetFormFieldsNullId() {
        Test.startTest();
        try {
            RoseFormService.getFormFields(null);
            System.assert(false, 'Should throw exception');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Exception expected');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testValidateFormResponseValid() {
        Form_Definition__c formDef = [SELECT Id FROM Form_Definition__c LIMIT 1];
        
        Map<String, Object> data = new Map<String, Object>{
            'FirstName' => 'John',
            'LastName' => 'Doe',
            'Email' => 'john.doe@example.com'
        };
        
        Test.startTest();
        RoseFormService.ValidationResult result = RoseFormService.validateFormResponse(data, formDef.Id);
        Test.stopTest();
        
        System.assertEquals(true, result.isValid, 'Validation should pass');
        System.assertEquals(0, result.errors.size(), 'Should have no errors');
    }
    
    @isTest
    static void testValidateFormResponseMissingRequired() {
        Form_Definition__c formDef = [SELECT Id FROM Form_Definition__c LIMIT 1];
        
        Map<String, Object> data = new Map<String, Object>{
            'Email' => 'john.doe@example.com'
        };
        
        Test.startTest();
        RoseFormService.ValidationResult result = RoseFormService.validateFormResponse(data, formDef.Id);
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail');
        System.assert(result.errors.size() > 0, 'Should have validation errors');
    }
    
    @isTest
    static void testValidateFormResponseEmpty() {
        Form_Definition__c formDef = [SELECT Id FROM Form_Definition__c LIMIT 1];
        
        Test.startTest();
        RoseFormService.ValidationResult result = RoseFormService.validateFormResponse(
            new Map<String, Object>(),
            formDef.Id
        );
        Test.stopTest();
        
        System.assertEquals(false, result.isValid, 'Validation should fail for empty data');
    }
    
    @isTest
    static void testProcessFormResponse() {
        Form_Definition__c formDef = [SELECT Id FROM Form_Definition__c LIMIT 1];
        
        // Create job and task
        Field_User__c fieldUser = new Field_User__c(Name = 'Test User', Status__c = 'Active');
        insert fieldUser;
        
        Job__c job = new Job__c(
            Name = 'Test Job',
            Assigned_User__c = fieldUser.Id,
            Status__c = 'New'
        );
        insert job;
        
        Task__c task = new Task__c(
            Name = 'Test Task',
            Job__c = job.Id,
            Task_Type__c = 'Collect Data',
            Sequence_Order__c = 1,
            Status__c = 'Pending'
        );
        insert task;
        
        // Create form response
        String responseData = '{"FirstName":"John","LastName":"Doe","Email":"john.doe@example.com"}';
        
        Form_Response__c response = new Form_Response__c(
            Task__c = task.Id,
            Form_Definition__c = formDef.Id,
            Response_Data__c = responseData,
            Submitted_Date__c = DateTime.now()
        );
        insert response;
        
        Test.startTest();
        String recordId = RoseFormService.processFormResponse(response);
        Test.stopTest();
        
        System.assertNotEquals(null, recordId, 'Should create a Contact record');
        
        // Verify contact was created
        Contact createdContact = [SELECT FirstName, LastName, Email FROM Contact WHERE Id = :recordId];
        System.assertEquals('John', createdContact.FirstName, 'FirstName should match');
        System.assertEquals('Doe', createdContact.LastName, 'LastName should match');
    }
}
