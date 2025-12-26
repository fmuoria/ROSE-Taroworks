/**
 * Test class for ROSEMediaService
 */
@IsTest
private class ROSEMediaService_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create required objects for form response
        ROSE_Field_User__c fieldUser = new ROSE_Field_User__c(
            Name = 'Test User',
            Status__c = 'Active'
        );
        insert fieldUser;
        
        ROSE_Job__c job = new ROSE_Job__c(
            Name = 'Test Job',
            Assigned_User__c = fieldUser.Id,
            Status__c = 'New'
        );
        insert job;
        
        ROSE_Task__c task = new ROSE_Task__c(
            ROSE_Job__c = job.Id,
            Name = 'Test Task',
            Task_Type__c = 'Collect Data',
            Status__c = 'Pending'
        );
        insert task;
        
        ROSE_Form_Definition__c formDef = new ROSE_Form_Definition__c(
            Name = 'Test Form',
            Active__c = true,
            Target_Object__c = 'Contact'
        );
        insert formDef;
        
        ROSE_Form_Response__c response = new ROSE_Form_Response__c(
            ROSE_Task__c = task.Id,
            ROSE_Form_Definition__c = formDef.Id,
            Response_Data__c = '{}',
            Submitted_Date__c = DateTime.now()
        );
        insert response;
    }
    
    @IsTest
    static void testUploadPhoto() {
        ROSE_Form_Response__c response = [SELECT Id FROM ROSE_Form_Response__c LIMIT 1];
        
        // Create a small test image (1x1 pixel PNG)
        String base64Image = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
        
        Test.startTest();
        Id mediaId = ROSEMediaService.uploadPhoto(base64Image, response.Id, 'Photo__c', 'test.png');
        Test.stopTest();
        
        System.assertNotEquals(null, mediaId, 'Media ID should not be null');
        
        ROSE_Media_Attachment__c media = [
            SELECT Id, File_Name__c, Field_Name__c, Content_Version__c, Synced__c
            FROM ROSE_Media_Attachment__c
            WHERE Id = :mediaId
        ];
        
        System.assertEquals('test.png', media.File_Name__c, 'File name should match');
        System.assertEquals('Photo__c', media.Field_Name__c, 'Field name should match');
        System.assertNotEquals(null, media.Content_Version__c, 'Content Version should be set');
        System.assertEquals(true, media.Synced__c, 'Should be marked as synced');
    }
    
    @IsTest
    static void testUploadPhotoInvalidData() {
        ROSE_Form_Response__c response = [SELECT Id FROM ROSE_Form_Response__c LIMIT 1];
        
        try {
            Test.startTest();
            ROSEMediaService.uploadPhoto('', response.Id, 'Photo__c', 'test.png');
            Test.stopTest();
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(true, 'Exception expected for empty base64 data');
        }
    }
    
    @IsTest
    static void testCaptureGPS() {
        ROSE_Form_Response__c response = [SELECT Id FROM ROSE_Form_Response__c LIMIT 1];
        
        Decimal latitude = 37.7749;
        Decimal longitude = -122.4194;
        
        Test.startTest();
        ROSEMediaService.captureGPS(latitude, longitude, response.Id);
        Test.stopTest();
        
        ROSE_Form_Response__c updatedResponse = [
            SELECT GPS_Latitude__c, GPS_Longitude__c
            FROM ROSE_Form_Response__c
            WHERE Id = :response.Id
        ];
        
        System.assertEquals(latitude, updatedResponse.GPS_Latitude__c, 'Latitude should match');
        System.assertEquals(longitude, updatedResponse.GPS_Longitude__c, 'Longitude should match');
    }
    
    @IsTest
    static void testCaptureGPSInvalidLatitude() {
        ROSE_Form_Response__c response = [SELECT Id FROM ROSE_Form_Response__c LIMIT 1];
        
        try {
            Test.startTest();
            ROSEMediaService.captureGPS(91, -122, response.Id);
            Test.stopTest();
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Latitude'), 'Error should mention latitude');
        }
    }
    
    @IsTest
    static void testCaptureGPSInvalidLongitude() {
        ROSE_Form_Response__c response = [SELECT Id FROM ROSE_Form_Response__c LIMIT 1];
        
        try {
            Test.startTest();
            ROSEMediaService.captureGPS(37, -181, response.Id);
            Test.stopTest();
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Longitude'), 'Error should mention longitude');
        }
    }
    
    @IsTest
    static void testCaptureGPSNullValues() {
        ROSE_Form_Response__c response = [SELECT Id FROM ROSE_Form_Response__c LIMIT 1];
        
        try {
            Test.startTest();
            ROSEMediaService.captureGPS(null, null, response.Id);
            Test.stopTest();
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(true, 'Exception expected for null coordinates');
        }
    }
    
    @IsTest
    static void testBulkPhotoUpload() {
        ROSE_Form_Response__c response = [SELECT Id FROM ROSE_Form_Response__c LIMIT 1];
        String base64Image = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
        
        Test.startTest();
        List<Id> mediaIds = new List<Id>();
        for (Integer i = 0; i < 10; i++) {
            try {
                Id mediaId = ROSEMediaService.uploadPhoto(base64Image, response.Id, 'Photo' + i + '__c', 'test' + i + '.png');
                mediaIds.add(mediaId);
            } catch (Exception e) {
                System.debug('Error uploading photo: ' + e.getMessage());
            }
        }
        Test.stopTest();
        
        System.assertEquals(10, mediaIds.size(), 'Should have uploaded 10 photos');
    }
}
