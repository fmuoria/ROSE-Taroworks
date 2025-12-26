/**
 * Service class for media upload and GPS operations
 */
public with sharing class ROSEMediaService {
    
    /**
     * Upload photo as ContentVersion and create media attachment record
     * @param base64Data Base64 encoded image data
     * @param formResponseId ID of form response
     * @param fieldName API name of the field
     * @param fileName Name of the file
     * @return ID of created media attachment
     */
    @AuraEnabled
    public static Id uploadPhoto(String base64Data, Id formResponseId, String fieldName, String fileName) {
        try {
            if (String.isBlank(base64Data) || formResponseId == null) {
                throw new IllegalArgumentException('Base64 data and form response ID are required');
            }
            
            // Create ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.IsMajorVersion = true;
            insert cv;
            
            // Get ContentDocumentId
            cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
            
            // Create media attachment record
            ROSE_Media_Attachment__c media = new ROSE_Media_Attachment__c(
                ROSE_Form_Response__c = formResponseId,
                Field_Name__c = fieldName,
                File_Name__c = fileName,
                Content_Version__c = cv.Id,
                Captured_Date__c = DateTime.now(),
                Synced__c = true
            );
            insert media;
            
            return media.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error uploading photo: ' + e.getMessage());
        }
    }
    
    /**
     * Capture GPS coordinates and update form response
     * @param latitude GPS latitude
     * @param longitude GPS longitude
     * @param formResponseId ID of form response
     */
    @AuraEnabled
    public static void captureGPS(Decimal latitude, Decimal longitude, Id formResponseId) {
        try {
            if (formResponseId == null) {
                throw new IllegalArgumentException('Form response ID is required');
            }
            
            if (latitude == null || longitude == null) {
                throw new IllegalArgumentException('Latitude and longitude are required');
            }
            
            // Validate latitude and longitude ranges
            if (latitude < -90 || latitude > 90) {
                throw new IllegalArgumentException('Latitude must be between -90 and 90');
            }
            
            if (longitude < -180 || longitude > 180) {
                throw new IllegalArgumentException('Longitude must be between -180 and 180');
            }
            
            ROSE_Form_Response__c response = new ROSE_Form_Response__c(
                Id = formResponseId,
                GPS_Latitude__c = latitude,
                GPS_Longitude__c = longitude
            );
            
            update response;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error capturing GPS: ' + e.getMessage());
        }
    }
}
