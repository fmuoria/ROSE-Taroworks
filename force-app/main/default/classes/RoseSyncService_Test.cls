/**
 * @description Test class for RoseSyncService
 * @author ROSE Team
 * @date 2025
 */
@isTest
private class RoseSyncService_Test {
    
    @testSetup
    static void setup() {
        // Create field user
        Field_User__c fieldUser = new Field_User__c(
            Name = 'Test Field User',
            Status__c = 'Active',
            Region__c = 'North'
        );
        insert fieldUser;
        
        // Create form definition
        Form_Definition__c formDef = new Form_Definition__c(
            Name = 'Test Form',
            Target_Object__c = 'Contact',
            Version__c = '1.0',
            Active__c = true
        );
        insert formDef;
        
        // Create form field
        Form_Field__c field = new Form_Field__c(
            Form_Definition__c = formDef.Id,
            Field_API_Name__c = 'FirstName',
            Field_Label__c = 'First Name',
            Field_Type__c = 'Text',
            Required__c = true,
            Display_Order__c = 1
        );
        insert field;
        
        // Create job
        Job__c job = new Job__c(
            Name = 'Test Job',
            Assigned_User__c = fieldUser.Id,
            Status__c = 'New',
            Priority__c = 'High',
            Due_Date__c = Date.today().addDays(7)
        );
        insert job;
        
        // Create task
        Task__c task = new Task__c(
            Name = 'Test Task',
            Job__c = job.Id,
            Task_Type__c = 'Collect Data',
            Form_Definition__c = formDef.Id,
            Sequence_Order__c = 1,
            Status__c = 'Pending'
        );
        insert task;
    }
    
    @isTest
    static void testSyncMetadata() {
        Test.startTest();
        RoseDataTransferObjects.MetadataPayload metadata = RoseSyncService.syncMetadata(null);
        Test.stopTest();
        
        System.assertEquals(1, metadata.formDefinitions.size(), 'Should return 1 form definition');
        System.assertEquals(1, metadata.formFields.size(), 'Should have form fields');
    }
    
    @isTest
    static void testSyncAssignments() {
        Field_User__c fieldUser = [SELECT Id FROM Field_User__c LIMIT 1];
        
        Test.startTest();
        RoseDataTransferObjects.AssignmentPayload assignments = 
            RoseSyncService.syncAssignments(fieldUser.Id, null);
        Test.stopTest();
        
        System.assertEquals(1, assignments.jobs.size(), 'Should return 1 job');
        System.assertEquals(1, assignments.tasks.size(), 'Should have tasks');
    }
    
    @isTest
    static void testUploadFormResponses() {
        Task__c task = [SELECT Id, Form_Definition__c FROM Task__c LIMIT 1];
        
        RoseDataTransferObjects.FormResponseDTO responseDTO = 
            new RoseDataTransferObjects.FormResponseDTO();
        responseDTO.taskId = task.Id;
        responseDTO.formDefinitionId = task.Form_Definition__c;
        responseDTO.responseData = '{"FirstName":"John"}';
        responseDTO.submittedDate = DateTime.now();
        
        Test.startTest();
        List<RoseDataTransferObjects.UploadStatus> statuses = 
            RoseSyncService.uploadFormResponses(new List<RoseDataTransferObjects.FormResponseDTO>{ responseDTO });
        Test.stopTest();
        
        System.assertEquals(1, statuses.size(), 'Should return 1 status');
        System.assertEquals(true, statuses[0].success, 'Upload should be successful');
    }
    
    @isTest
    static void testUploadMedia() {
        // Create form response first
        Task__c task = [SELECT Id FROM Task__c LIMIT 1];
        Form_Response__c response = new Form_Response__c(
            Task__c = task.Id,
            Response_Data__c = '{"test":"data"}',
            Submitted_Date__c = DateTime.now()
        );
        insert response;
        
        RoseDataTransferObjects.MediaDTO mediaDTO = new RoseDataTransferObjects.MediaDTO();
        mediaDTO.formResponseId = response.Id;
        mediaDTO.fieldName = 'photo_field';
        mediaDTO.fileName = 'test.jpg';
        mediaDTO.fileData = EncodingUtil.base64Encode(Blob.valueOf('Test data'));
        
        Test.startTest();
        List<RoseDataTransferObjects.UploadStatus> statuses = 
            RoseSyncService.uploadMedia(new List<RoseDataTransferObjects.MediaDTO>{ mediaDTO });
        Test.stopTest();
        
        System.assertEquals(1, statuses.size(), 'Should return 1 status');
        System.assertEquals(true, statuses[0].success, 'Upload should be successful');
    }
    
    @isTest
    static void testPerformSyncSuccess() {
        Field_User__c fieldUser = [SELECT Id FROM Field_User__c LIMIT 1];
        
        RoseDataTransferObjects.SyncRequest request = new RoseDataTransferObjects.SyncRequest();
        request.userId = fieldUser.Id;
        request.lastSyncTime = DateTime.now().addDays(-1);
        
        Test.startTest();
        RoseDataTransferObjects.SyncResult result = RoseSyncService.performSync(fieldUser.Id, request);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Sync should be successful');
        System.assertNotEquals(null, result.metadata, 'Metadata should be present');
        System.assertNotEquals(null, result.assignments, 'Assignments should be present');
    }
    
    @isTest
    static void testPerformSyncWithUploads() {
        Field_User__c fieldUser = [SELECT Id FROM Field_User__c LIMIT 1];
        Task__c task = [SELECT Id, Form_Definition__c FROM Task__c LIMIT 1];
        
        // Create sync request with pending response
        RoseDataTransferObjects.SyncRequest request = new RoseDataTransferObjects.SyncRequest();
        request.userId = fieldUser.Id;
        request.lastSyncTime = DateTime.now().addDays(-1);
        
        RoseDataTransferObjects.FormResponseDTO responseDTO = 
            new RoseDataTransferObjects.FormResponseDTO();
        responseDTO.taskId = task.Id;
        responseDTO.formDefinitionId = task.Form_Definition__c;
        responseDTO.responseData = '{"FirstName":"John"}';
        responseDTO.submittedDate = DateTime.now();
        request.pendingResponses.add(responseDTO);
        
        Test.startTest();
        RoseDataTransferObjects.SyncResult result = RoseSyncService.performSync(fieldUser.Id, request);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'Sync should be successful');
        System.assertEquals(1, result.uploadStatuses.size(), 'Should have 1 upload status');
    }
    
    @isTest
    static void testLogSync() {
        Field_User__c fieldUser = [SELECT Id FROM Field_User__c LIMIT 1];
        
        RoseDataTransferObjects.SyncResult result = new RoseDataTransferObjects.SyncResult();
        result.success = true;
        result.recordsUp = 5;
        result.recordsDown = 10;
        
        Test.startTest();
        RoseSyncService.logSync(fieldUser.Id, result, DateTime.now());
        Test.stopTest();
        
        List<Sync_Log__c> logs = [SELECT Status__c, Records_Up__c, Records_Down__c FROM Sync_Log__c];
        System.assertEquals(1, logs.size(), 'Should create 1 sync log');
        System.assertEquals('Success', logs[0].Status__c, 'Status should be Success');
    }
    
    @isTest
    static void testCleanupSyncedJobs() {
        Field_User__c fieldUser = [SELECT Id FROM Field_User__c LIMIT 1];
        Job__c job = [SELECT Id FROM Job__c LIMIT 1];
        
        // Mark job as completed
        job.Status__c = 'Completed';
        job.Completed_Date__c = DateTime.now();
        update job;
        
        Test.startTest();
        RoseSyncService.cleanupSyncedJobs(fieldUser.Id);
        Test.stopTest();
        
        Job__c updatedJob = [SELECT Status__c, Synced_Date__c FROM Job__c WHERE Id = :job.Id];
        System.assertEquals('Synced', updatedJob.Status__c, 'Job should be marked as Synced');
        System.assertNotEquals(null, updatedJob.Synced_Date__c, 'Synced date should be set');
    }
}
