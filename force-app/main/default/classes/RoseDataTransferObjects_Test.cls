/**
 * @description Test class for RoseDataTransferObjects
 * @author ROSE Team
 * @date 2025
 */
@isTest
private class RoseDataTransferObjects_Test {
    
    @isTest
    static void testSyncRequest() {
        RoseDataTransferObjects.SyncRequest request = new RoseDataTransferObjects.SyncRequest();
        request.userId = 'testUser123';
        request.lastSyncTime = DateTime.now();
        
        System.assertNotEquals(null, request.pendingResponses, 'Pending responses should be initialized');
        System.assertNotEquals(null, request.pendingMedia, 'Pending media should be initialized');
        System.assertEquals('testUser123', request.userId, 'User ID should match');
    }
    
    @isTest
    static void testSyncResult() {
        RoseDataTransferObjects.SyncResult result = new RoseDataTransferObjects.SyncResult();
        result.success = true;
        result.message = 'Sync completed successfully';
        result.recordsUp = 5;
        result.recordsDown = 10;
        
        System.assertEquals(true, result.success, 'Success should be true');
        System.assertEquals('Sync completed successfully', result.message, 'Message should match');
        System.assertEquals(5, result.recordsUp, 'Records up should be 5');
        System.assertEquals(10, result.recordsDown, 'Records down should be 10');
        System.assertNotEquals(null, result.syncTime, 'Sync time should be set');
    }
    
    @isTest
    static void testFormResponseDTO() {
        RoseDataTransferObjects.FormResponseDTO response = new RoseDataTransferObjects.FormResponseDTO();
        response.id = 'resp123';
        response.taskId = 'task123';
        response.formDefinitionId = 'form123';
        response.responseData = '{"field1":"value1"}';
        response.gpsLatitude = 37.7749;
        response.gpsLongitude = -122.4194;
        
        System.assertEquals('resp123', response.id, 'ID should match');
        System.assertEquals('task123', response.taskId, 'Task ID should match');
        System.assertEquals(37.7749, response.gpsLatitude, 'GPS latitude should match');
    }
    
    @isTest
    static void testMediaDTO() {
        RoseDataTransferObjects.MediaDTO media = new RoseDataTransferObjects.MediaDTO();
        media.id = 'media123';
        media.formResponseId = 'resp123';
        media.fieldName = 'photo_field';
        media.fileName = 'photo.jpg';
        media.fileData = 'base64encodedstring';
        
        System.assertEquals('media123', media.id, 'ID should match');
        System.assertEquals('resp123', media.formResponseId, 'Form response ID should match');
        System.assertEquals('photo.jpg', media.fileName, 'File name should match');
    }
    
    @isTest
    static void testMetadataPayload() {
        RoseDataTransferObjects.MetadataPayload metadata = new RoseDataTransferObjects.MetadataPayload();
        
        System.assertNotEquals(null, metadata.formDefinitions, 'Form definitions should be initialized');
        System.assertNotEquals(null, metadata.formFields, 'Form fields should be initialized');
    }
    
    @isTest
    static void testFormDefinitionDTO() {
        RoseDataTransferObjects.FormDefinitionDTO formDef = new RoseDataTransferObjects.FormDefinitionDTO();
        formDef.id = 'form123';
        formDef.name = 'Test Form';
        formDef.targetObject = 'Contact';
        formDef.version = '1.0';
        formDef.active = true;
        
        System.assertEquals('form123', formDef.id, 'ID should match');
        System.assertEquals('Test Form', formDef.name, 'Name should match');
        System.assertEquals(true, formDef.active, 'Active should be true');
    }
    
    @isTest
    static void testFormFieldDTO() {
        RoseDataTransferObjects.FormFieldDTO field = new RoseDataTransferObjects.FormFieldDTO();
        field.id = 'field123';
        field.fieldApiName = 'FirstName';
        field.fieldLabel = 'First Name';
        field.fieldType = 'Text';
        field.required = true;
        field.displayOrder = 1;
        
        System.assertEquals('field123', field.id, 'ID should match');
        System.assertEquals('FirstName', field.fieldApiName, 'API name should match');
        System.assertEquals(true, field.required, 'Required should be true');
    }
    
    @isTest
    static void testAssignmentPayload() {
        RoseDataTransferObjects.AssignmentPayload assignments = new RoseDataTransferObjects.AssignmentPayload();
        
        System.assertNotEquals(null, assignments.jobs, 'Jobs should be initialized');
        System.assertNotEquals(null, assignments.tasks, 'Tasks should be initialized');
    }
    
    @isTest
    static void testJobDTO() {
        RoseDataTransferObjects.JobDTO job = new RoseDataTransferObjects.JobDTO();
        job.id = 'job123';
        job.name = 'Test Job';
        job.status = 'New';
        job.priority = 'High';
        job.dueDate = Date.today().addDays(7);
        
        System.assertEquals('job123', job.id, 'ID should match');
        System.assertEquals('Test Job', job.name, 'Name should match');
        System.assertEquals('High', job.priority, 'Priority should match');
    }
    
    @isTest
    static void testTaskDTO() {
        RoseDataTransferObjects.TaskDTO task = new RoseDataTransferObjects.TaskDTO();
        task.id = 'task123';
        task.jobId = 'job123';
        task.name = 'Test Task';
        task.taskType = 'Collect Data';
        task.sequenceOrder = 1;
        task.status = 'Pending';
        
        System.assertEquals('task123', task.id, 'ID should match');
        System.assertEquals('job123', task.jobId, 'Job ID should match');
        System.assertEquals('Collect Data', task.taskType, 'Task type should match');
    }
    
    @isTest
    static void testUploadStatus() {
        RoseDataTransferObjects.UploadStatus status = new RoseDataTransferObjects.UploadStatus();
        status.id = 'upload123';
        status.recordType = 'FormResponse';
        status.success = true;
        status.message = 'Upload successful';
        status.serverId = 'serverRec123';
        
        System.assertEquals('upload123', status.id, 'ID should match');
        System.assertEquals('FormResponse', status.recordType, 'Record type should match');
        System.assertEquals(true, status.success, 'Success should be true');
        System.assertEquals('serverRec123', status.serverId, 'Server ID should match');
    }
}
