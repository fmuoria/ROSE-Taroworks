/**
 * Test class for ROSESyncService
 */
@IsTest
private class ROSESyncService_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create user
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        // Create field user
        ROSE_Field_User__c fieldUser = new ROSE_Field_User__c(
            Name = 'Test Field User',
            User__c = testUser.Id,
            Status__c = 'Active',
            Region__c = 'North'
        );
        insert fieldUser;
        
        // Create form definition
        ROSE_Form_Definition__c formDef = new ROSE_Form_Definition__c(
            Name = 'Contact Form',
            Target_Object__c = 'Contact',
            Version__c = 1.0,
            Active__c = true
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
            )
        };
        insert fields;
        
        // Create job
        ROSE_Job__c job = new ROSE_Job__c(
            Name = 'Test Job',
            Assigned_User__c = fieldUser.Id,
            Status__c = 'New',
            Priority__c = 'High',
            Due_Date__c = Date.today().addDays(7)
        );
        insert job;
        
        // Create task
        ROSE_Task__c task = new ROSE_Task__c(
            ROSE_Job__c = job.Id,
            Name = 'Collect Contact Data',
            Task_Type__c = 'Collect Data',
            ROSE_Form_Definition__c = formDef.Id,
            Sequence_Order__c = 1,
            Status__c = 'Pending'
        );
        insert task;
    }
    
    @IsTest
    static void testPerformSyncSuccess() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        ROSE_Form_Definition__c formDef = [SELECT Id FROM ROSE_Form_Definition__c LIMIT 1];
        ROSE_Task__c task = [SELECT Id FROM ROSE_Task__c LIMIT 1];
        
        // Create sync request
        ROSEDataTransferObjects.SyncRequest request = new ROSEDataTransferObjects.SyncRequest();
        request.lastMetadataSync = DateTime.now().addDays(-7);
        request.lastAssignmentSync = DateTime.now().addDays(-1);
        
        // Add form response
        ROSEDataTransferObjects.FormResponseDTO responseDTO = new ROSEDataTransferObjects.FormResponseDTO();
        responseDTO.taskId = task.Id;
        responseDTO.formDefinitionId = formDef.Id;
        responseDTO.responseDataJSON = '{"FirstName":"John","LastName":"Doe"}';
        responseDTO.latitude = 37.7749;
        responseDTO.longitude = -122.4194;
        responseDTO.submittedDate = DateTime.now();
        request.formResponses.add(responseDTO);
        
        String syncRequestJSON = JSON.serialize(request);
        
        Test.startTest();
        ROSEDataTransferObjects.SyncResult result = ROSESyncService.performSync(testUser.Id, syncRequestJSON);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Sync should be successful');
        System.assertNotEquals(null, result.metadata, 'Metadata should not be null');
        System.assertNotEquals(null, result.assignments, 'Assignments should not be null');
        System.assertNotEquals(null, result.uploadStatus, 'Upload status should not be null');
        
        // Verify sync log was created
        List<ROSE_Sync_Log__c> logs = [SELECT Id, Status__c FROM ROSE_Sync_Log__c];
        System.assertNotEquals(0, logs.size(), 'Sync log should be created');
        System.assertEquals('Success', logs[0].Status__c, 'Log status should be Success');
    }
    
    @IsTest
    static void testPerformSyncInvalidUser() {
        ROSEDataTransferObjects.SyncRequest request = new ROSEDataTransferObjects.SyncRequest();
        String syncRequestJSON = JSON.serialize(request);
        
        Test.startTest();
        ROSEDataTransferObjects.SyncResult result = ROSESyncService.performSync('invalidUserId', syncRequestJSON);
        Test.stopTest();
        
        System.assertEquals(false, result.success, 'Sync should fail for invalid user');
        System.assertNotEquals(null, result.errorMessage, 'Error message should be set');
    }
    
    @IsTest
    static void testMetadataSync() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        // Create sync request with metadata sync
        ROSEDataTransferObjects.SyncRequest request = new ROSEDataTransferObjects.SyncRequest();
        request.lastMetadataSync = DateTime.now().addDays(-7);
        String syncRequestJSON = JSON.serialize(request);
        
        Test.startTest();
        ROSEDataTransferObjects.SyncResult result = ROSESyncService.performSync(testUser.Id, syncRequestJSON);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Sync should be successful');
        System.assertNotEquals(null, result.metadata, 'Metadata should not be null');
        System.assertNotEquals(null, result.metadata.formDefinitions, 'Form definitions should not be null');
        System.assertNotEquals(0, result.metadata.formDefinitions.size(), 'Should have form definitions');
        System.assertNotEquals(0, result.metadata.formFields.size(), 'Should have form fields');
    }
    
    @IsTest
    static void testAssignmentSync() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
        // Create sync request with assignment sync
        ROSEDataTransferObjects.SyncRequest request = new ROSEDataTransferObjects.SyncRequest();
        request.lastAssignmentSync = DateTime.now().addDays(-1);
        String syncRequestJSON = JSON.serialize(request);
        
        Test.startTest();
        ROSEDataTransferObjects.SyncResult result = ROSESyncService.performSync(testUser.Id, syncRequestJSON);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Sync should be successful');
        System.assertNotEquals(null, result.assignments, 'Assignments should not be null');
        System.assertNotEquals(null, result.assignments.jobs, 'Jobs should not be null');
        System.assertNotEquals(0, result.assignments.jobs.size(), 'Should have jobs');
        System.assertNotEquals(0, result.assignments.tasks.size(), 'Should have tasks');
    }
    
    @IsTest
    static void testUploadFormResponses() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        ROSE_Form_Definition__c formDef = [SELECT Id FROM ROSE_Form_Definition__c LIMIT 1];
        ROSE_Task__c task = [SELECT Id FROM ROSE_Task__c LIMIT 1];
        
        // Create sync request with form responses
        ROSEDataTransferObjects.SyncRequest request = new ROSEDataTransferObjects.SyncRequest();
        
        ROSEDataTransferObjects.FormResponseDTO responseDTO = new ROSEDataTransferObjects.FormResponseDTO();
        responseDTO.taskId = task.Id;
        responseDTO.formDefinitionId = formDef.Id;
        responseDTO.responseDataJSON = '{"FirstName":"Jane","LastName":"Smith"}';
        responseDTO.submittedDate = DateTime.now();
        request.formResponses.add(responseDTO);
        
        String syncRequestJSON = JSON.serialize(request);
        
        Test.startTest();
        ROSEDataTransferObjects.SyncResult result = ROSESyncService.performSync(testUser.Id, syncRequestJSON);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Sync should be successful');
        System.assertEquals(1, result.uploadStatus.successCount, 'Should have 1 successful upload');
        
        // Verify form response was created
        List<ROSE_Form_Response__c> responses = [SELECT Id, Synced__c FROM ROSE_Form_Response__c];
        System.assertNotEquals(0, responses.size(), 'Form response should be created');
        System.assertEquals(true, responses[0].Synced__c, 'Form response should be synced');
        
        // Verify contact was created
        List<Contact> contacts = [SELECT FirstName, LastName FROM Contact];
        System.assertNotEquals(0, contacts.size(), 'Contact should be created');
    }
    
    @IsTest
    static void testCleanupSyncedJobs() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        ROSE_Job__c job = [SELECT Id FROM ROSE_Job__c LIMIT 1];
        ROSE_Task__c task = [SELECT Id FROM ROSE_Task__c LIMIT 1];
        ROSE_Form_Definition__c formDef = [SELECT Id FROM ROSE_Form_Definition__c LIMIT 1];
        
        // Complete job
        job.Status__c = 'Completed';
        job.Completed_Date__c = DateTime.now();
        update job;
        
        // Create synced form response
        ROSE_Form_Response__c response = new ROSE_Form_Response__c(
            ROSE_Task__c = task.Id,
            ROSE_Form_Definition__c = formDef.Id,
            Response_Data__c = '{}',
            Synced__c = true,
            Sync_Status__c = 'Success'
        );
        insert response;
        
        ROSEDataTransferObjects.SyncRequest request = new ROSEDataTransferObjects.SyncRequest();
        String syncRequestJSON = JSON.serialize(request);
        
        Test.startTest();
        ROSEDataTransferObjects.SyncResult result = ROSESyncService.performSync(testUser.Id, syncRequestJSON);
        Test.stopTest();
        
        // Verify job status updated to Synced
        ROSE_Job__c updatedJob = [SELECT Status__c, Synced_Date__c FROM ROSE_Job__c WHERE Id = :job.Id];
        System.assertEquals('Synced', updatedJob.Status__c, 'Job should be marked as Synced');
        System.assertNotEquals(null, updatedJob.Synced_Date__c, 'Synced date should be set');
    }
    
    @IsTest
    static void testBulkSync() {
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        ROSE_Form_Definition__c formDef = [SELECT Id FROM ROSE_Form_Definition__c LIMIT 1];
        ROSE_Task__c task = [SELECT Id FROM ROSE_Task__c LIMIT 1];
        
        // Create sync request with 50 form responses
        ROSEDataTransferObjects.SyncRequest request = new ROSEDataTransferObjects.SyncRequest();
        
        for (Integer i = 0; i < 50; i++) {
            ROSEDataTransferObjects.FormResponseDTO responseDTO = new ROSEDataTransferObjects.FormResponseDTO();
            responseDTO.taskId = task.Id;
            responseDTO.formDefinitionId = formDef.Id;
            responseDTO.responseDataJSON = '{"FirstName":"User' + i + '","LastName":"Test' + i + '"}';
            responseDTO.submittedDate = DateTime.now();
            request.formResponses.add(responseDTO);
        }
        
        String syncRequestJSON = JSON.serialize(request);
        
        Test.startTest();
        ROSEDataTransferObjects.SyncResult result = ROSESyncService.performSync(testUser.Id, syncRequestJSON);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Bulk sync should be successful');
        System.assertNotEquals(0, result.uploadStatus.successCount, 'Should have successful uploads');
    }
}
