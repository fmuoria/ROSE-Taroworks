/**
 * @description Test class for RoseMediaService
 * @author ROSE Team
 * @date 2025
 */
@isTest
private class RoseMediaService_Test {
    
    @testSetup
    static void setup() {
        // Create test data
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
        
        Form_Response__c response = new Form_Response__c(
            Task__c = task.Id,
            Response_Data__c = '{"field1":"value1"}',
            Submitted_Date__c = DateTime.now()
        );
        insert response;
    }
    
    @isTest
    static void testUploadPhoto() {
        Form_Response__c response = [SELECT Id FROM Form_Response__c LIMIT 1];
        
        Blob photoData = Blob.valueOf('Test photo data');
        
        Test.startTest();
        String mediaId = RoseMediaService.uploadPhoto(photoData, response.Id, 'photo_field');
        Test.stopTest();
        
        System.assertNotEquals(null, mediaId, 'Media ID should not be null');
        
        Media_Attachment__c media = [SELECT Field_Name__c, File_Name__c FROM Media_Attachment__c WHERE Id = :mediaId];
        System.assertEquals('photo_field', media.Field_Name__c, 'Field name should match');
    }
    
    @isTest
    static void testUploadPhotoNullData() {
        Form_Response__c response = [SELECT Id FROM Form_Response__c LIMIT 1];
        
        Test.startTest();
        try {
            RoseMediaService.uploadPhoto(null, response.Id, 'photo_field');
            System.assert(false, 'Should throw exception');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Exception expected');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCaptureGPS() {
        Form_Response__c response = [SELECT Id FROM Form_Response__c LIMIT 1];
        
        Test.startTest();
        RoseMediaService.captureGPS(37.7749, -122.4194, response.Id);
        Test.stopTest();
        
        Form_Response__c updatedResponse = [
            SELECT GPS_Latitude__c, GPS_Longitude__c
            FROM Form_Response__c
            WHERE Id = :response.Id
        ];
        
        System.assertEquals(37.7749, updatedResponse.GPS_Latitude__c, 'Latitude should match');
        System.assertEquals(-122.4194, updatedResponse.GPS_Longitude__c, 'Longitude should match');
    }
    
    @isTest
    static void testCaptureGPSNullCoordinates() {
        Form_Response__c response = [SELECT Id FROM Form_Response__c LIMIT 1];
        
        Test.startTest();
        try {
            RoseMediaService.captureGPS(null, null, response.Id);
            System.assert(false, 'Should throw exception');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Exception expected');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testUploadMediaFromDTO() {
        Form_Response__c response = [SELECT Id FROM Form_Response__c LIMIT 1];
        
        RoseDataTransferObjects.MediaDTO mediaDTO = new RoseDataTransferObjects.MediaDTO();
        mediaDTO.formResponseId = response.Id;
        mediaDTO.fieldName = 'photo_field';
        mediaDTO.fileName = 'test.jpg';
        mediaDTO.fileData = EncodingUtil.base64Encode(Blob.valueOf('Test data'));
        mediaDTO.gpsLatitude = 37.7749;
        mediaDTO.gpsLongitude = -122.4194;
        
        Test.startTest();
        String mediaId = RoseMediaService.uploadMediaFromDTO(mediaDTO);
        Test.stopTest();
        
        System.assertNotEquals(null, mediaId, 'Media ID should not be null');
        
        Media_Attachment__c media = [
            SELECT GPS_Latitude__c, GPS_Longitude__c
            FROM Media_Attachment__c
            WHERE Id = :mediaId
        ];
        System.assertEquals(37.7749, media.GPS_Latitude__c, 'GPS latitude should match');
    }
    
    @isTest
    static void testGetMediaForFormResponse() {
        Form_Response__c response = [SELECT Id FROM Form_Response__c LIMIT 1];
        
        // Create media attachment
        Blob photoData = Blob.valueOf('Test photo data');
        RoseMediaService.uploadPhoto(photoData, response.Id, 'photo_field');
        
        Test.startTest();
        List<Media_Attachment__c> mediaList = RoseMediaService.getMediaForFormResponse(response.Id);
        Test.stopTest();
        
        System.assertEquals(1, mediaList.size(), 'Should return 1 media attachment');
    }
}
