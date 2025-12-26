/**
 * Test class for ROSEDataTransferObjects
 */
@IsTest
private class ROSEDataTransferObjects_Test {
    
    @IsTest
    static void testSyncRequest() {
        // Test SyncRequest initialization
        ROSEDataTransferObjects.SyncRequest request = new ROSEDataTransferObjects.SyncRequest();
        request.lastMetadataSync = DateTime.now().addDays(-1);
        request.lastAssignmentSync = DateTime.now().addHours(-2);
        
        // Verify defaults
        System.assertNotEquals(null, request.formResponses, 'Form responses should be initialized');
        System.assertNotEquals(null, request.mediaFiles, 'Media files should be initialized');
        System.assertEquals(0, request.formResponses.size(), 'Form responses should be empty');
        System.assertEquals(0, request.mediaFiles.size(), 'Media files should be empty');
        
        // Add form response
        ROSEDataTransferObjects.FormResponseDTO response = new ROSEDataTransferObjects.FormResponseDTO();
        response.taskId = 'test123';
        response.responseDataJSON = '{"field1":"value1"}';
        request.formResponses.add(response);
        
        System.assertEquals(1, request.formResponses.size(), 'Should have 1 form response');
    }
    
    @IsTest
    static void testSyncResult() {
        // Test SyncResult initialization
        ROSEDataTransferObjects.SyncResult result = new ROSEDataTransferObjects.SyncResult();
        
        // Verify defaults
        System.assertEquals(false, result.success, 'Success should default to false');
        System.assertNotEquals(null, result.timestamp, 'Timestamp should be initialized');
        System.assertNotEquals(null, result.conflicts, 'Conflicts should be initialized');
        System.assertEquals(0, result.conflicts.size(), 'Conflicts should be empty');
        
        // Set values
        result.success = true;
        result.errorMessage = null;
        
        System.assertEquals(true, result.success, 'Success should be true');
    }
    
    @IsTest
    static void testFormResponseDTO() {
        // Test FormResponseDTO
        ROSEDataTransferObjects.FormResponseDTO dto = new ROSEDataTransferObjects.FormResponseDTO();
        dto.taskId = 'a00123456789ABC';
        dto.formDefinitionId = 'a01123456789ABC';
        dto.responseDataJSON = '{"name":"Test","email":"test@example.com"}';
        dto.latitude = 37.7749;
        dto.longitude = -122.4194;
        dto.submittedDate = DateTime.now();
        dto.targetRecordId = '003123456789ABC';
        dto.objectType = 'Contact';
        dto.modifiedDate = DateTime.now();
        
        // Verify all fields can be set
        System.assertEquals('a00123456789ABC', dto.taskId, 'Task ID should match');
        System.assertEquals('Contact', dto.objectType, 'Object type should match');
        System.assertEquals(37.7749, dto.latitude, 'Latitude should match');
    }
    
    @IsTest
    static void testMediaDTO() {
        // Test MediaDTO
        ROSEDataTransferObjects.MediaDTO media = new ROSEDataTransferObjects.MediaDTO();
        media.formResponseId = 'a02123456789ABC';
        media.fieldName = 'Photo__c';
        media.fileName = 'photo.jpg';
        media.base64Data = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
        media.latitude = 40.7128;
        media.longitude = -74.0060;
        
        // Verify all fields can be set
        System.assertEquals('Photo__c', media.fieldName, 'Field name should match');
        System.assertEquals('photo.jpg', media.fileName, 'File name should match');
        System.assertNotEquals(null, media.base64Data, 'Base64 data should not be null');
    }
    
    @IsTest
    static void testMetadataPayload() {
        // Test MetadataPayload initialization
        ROSEDataTransferObjects.MetadataPayload payload = new ROSEDataTransferObjects.MetadataPayload();
        
        // Verify defaults
        System.assertNotEquals(null, payload.formDefinitions, 'Form definitions should be initialized');
        System.assertNotEquals(null, payload.formFields, 'Form fields should be initialized');
        System.assertEquals(0, payload.formDefinitions.size(), 'Form definitions should be empty');
        System.assertEquals(0, payload.formFields.size(), 'Form fields should be empty');
    }
    
    @IsTest
    static void testAssignmentPayload() {
        // Test AssignmentPayload initialization
        ROSEDataTransferObjects.AssignmentPayload payload = new ROSEDataTransferObjects.AssignmentPayload();
        
        // Verify defaults
        System.assertNotEquals(null, payload.jobs, 'Jobs should be initialized');
        System.assertNotEquals(null, payload.tasks, 'Tasks should be initialized');
        System.assertNotEquals(null, payload.targetRecords, 'Target records should be initialized');
        System.assertEquals(0, payload.jobs.size(), 'Jobs should be empty');
        System.assertEquals(0, payload.tasks.size(), 'Tasks should be empty');
        System.assertEquals(0, payload.targetRecords.size(), 'Target records should be empty');
    }
    
    @IsTest
    static void testUploadStatus() {
        // Test UploadStatus initialization
        ROSEDataTransferObjects.UploadStatus status = new ROSEDataTransferObjects.UploadStatus();
        
        // Verify defaults
        System.assertEquals(0, status.successCount, 'Success count should be 0');
        System.assertEquals(0, status.failureCount, 'Failure count should be 0');
        System.assertNotEquals(null, status.errors, 'Errors should be initialized');
        System.assertEquals(0, status.errors.size(), 'Errors should be empty');
        
        // Simulate upload results
        status.successCount = 10;
        status.failureCount = 2;
        status.errors.add('Error processing record 1');
        status.errors.add('Error processing record 2');
        
        System.assertEquals(10, status.successCount, 'Success count should be 10');
        System.assertEquals(2, status.failureCount, 'Failure count should be 2');
        System.assertEquals(2, status.errors.size(), 'Should have 2 errors');
    }
    
    @IsTest
    static void testBulkOperations() {
        // Test bulk scenarios
        ROSEDataTransferObjects.SyncRequest request = new ROSEDataTransferObjects.SyncRequest();
        
        // Add 200 form responses
        for (Integer i = 0; i < 200; i++) {
            ROSEDataTransferObjects.FormResponseDTO response = new ROSEDataTransferObjects.FormResponseDTO();
            response.taskId = 'task' + i;
            response.responseDataJSON = '{"index":' + i + '}';
            request.formResponses.add(response);
        }
        
        // Add 200 media files
        for (Integer i = 0; i < 200; i++) {
            ROSEDataTransferObjects.MediaDTO media = new ROSEDataTransferObjects.MediaDTO();
            media.fileName = 'file' + i + '.jpg';
            media.base64Data = 'data' + i;
            request.mediaFiles.add(media);
        }
        
        System.assertEquals(200, request.formResponses.size(), 'Should have 200 form responses');
        System.assertEquals(200, request.mediaFiles.size(), 'Should have 200 media files');
    }
}
