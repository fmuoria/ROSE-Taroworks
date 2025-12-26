/**
 * @description Service class for Media upload and GPS operations
 * @author ROSE Team
 * @date 2025
 */
public with sharing class RoseMediaService {
    
    /**
     * Upload photo and create media attachment
     * @param photoData Base64 encoded photo data
     * @param formResponseId The form response ID
     * @param fieldName The field name for the photo
     * @return Media attachment ID
     */
    public static String uploadPhoto(Blob photoData, Id formResponseId, String fieldName) {
        if (photoData == null) {
            throw new IllegalArgumentException('Photo data cannot be null');
        }
        if (formResponseId == null) {
            throw new IllegalArgumentException('Form response ID cannot be null');
        }
        if (String.isBlank(fieldName)) {
            throw new IllegalArgumentException('Field name cannot be blank');
        }
        
        String fileName = 'photo_' + DateTime.now().getTime() + '.jpg';
        
        // Create ContentVersion
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.VersionData = photoData;
        cv.IsMajorVersion = true;
        insert cv;
        
        // Get Content Document ID
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        // Create Media Attachment record
        Media_Attachment__c media = new Media_Attachment__c(
            Form_Response__c = formResponseId,
            Field_Name__c = fieldName,
            File_Name__c = fileName,
            Content_Version__c = cv.Id,
            Captured_Date__c = DateTime.now(),
            Synced__c = true
        );
        insert media;
        
        return media.Id;
    }
    
    /**
     * Capture GPS coordinates for form response
     * @param latitude GPS latitude
     * @param longitude GPS longitude
     * @param formResponseId The form response ID
     */
    public static void captureGPS(Decimal latitude, Decimal longitude, Id formResponseId) {
        if (formResponseId == null) {
            throw new IllegalArgumentException('Form response ID cannot be null');
        }
        if (latitude == null || longitude == null) {
            throw new IllegalArgumentException('GPS coordinates cannot be null');
        }
        
        Form_Response__c response = new Form_Response__c(
            Id = formResponseId,
            GPS_Latitude__c = latitude,
            GPS_Longitude__c = longitude
        );
        
        update response;
    }
    
    /**
     * Upload media from DTO
     * @param mediaDTO The media DTO containing file data
     * @return Media attachment ID
     */
    public static String uploadMediaFromDTO(RoseDataTransferObjects.MediaDTO mediaDTO) {
        if (mediaDTO == null) {
            throw new IllegalArgumentException('Media DTO cannot be null');
        }
        
        Blob fileData = EncodingUtil.base64Decode(mediaDTO.fileData);
        String mediaId = uploadPhoto(fileData, mediaDTO.formResponseId, mediaDTO.fieldName);
        
        // Update GPS if provided
        if (mediaDTO.gpsLatitude != null && mediaDTO.gpsLongitude != null) {
            Media_Attachment__c media = new Media_Attachment__c(
                Id = mediaId,
                GPS_Latitude__c = mediaDTO.gpsLatitude,
                GPS_Longitude__c = mediaDTO.gpsLongitude
            );
            update media;
        }
        
        return mediaId;
    }
    
    /**
     * Get media attachments for a form response
     * @param formResponseId The form response ID
     * @return List of media attachments
     */
    public static List<Media_Attachment__c> getMediaForFormResponse(Id formResponseId) {
        if (formResponseId == null) {
            throw new IllegalArgumentException('Form response ID cannot be null');
        }
        
        return [
            SELECT Id, Form_Response__c, Field_Name__c, File_Name__c,
                   Content_Version__c, GPS_Latitude__c, GPS_Longitude__c,
                   Captured_Date__c, Synced__c
            FROM Media_Attachment__c
            WHERE Form_Response__c = :formResponseId
            ORDER BY Captured_Date__c DESC
        ];
    }
}
