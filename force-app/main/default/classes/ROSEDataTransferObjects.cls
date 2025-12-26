/**
 * Data Transfer Objects for ROSE Taroworks System
 * Contains wrapper classes for data exchange between client and server
 */
public class ROSEDataTransferObjects {
    
    /**
     * Request wrapper for sync operations
     */
    public class SyncRequest {
        @AuraEnabled public DateTime lastMetadataSync { get; set; }
        @AuraEnabled public DateTime lastAssignmentSync { get; set; }
        @AuraEnabled public List<FormResponseDTO> formResponses { get; set; }
        @AuraEnabled public List<MediaDTO> mediaFiles { get; set; }
        
        public SyncRequest() {
            this.formResponses = new List<FormResponseDTO>();
            this.mediaFiles = new List<MediaDTO>();
        }
    }
    
    /**
     * Result wrapper for sync operations
     */
    public class SyncResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public DateTime timestamp { get; set; }
        @AuraEnabled public MetadataPayload metadata { get; set; }
        @AuraEnabled public AssignmentPayload assignments { get; set; }
        @AuraEnabled public UploadStatus uploadStatus { get; set; }
        @AuraEnabled public List<ROSE_Conflict_Queue__c> conflicts { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        
        public SyncResult() {
            this.success = false;
            this.timestamp = DateTime.now();
            this.conflicts = new List<ROSE_Conflict_Queue__c>();
        }
    }
    
    /**
     * DTO for form response data
     */
    public class FormResponseDTO {
        @AuraEnabled public String taskId { get; set; }
        @AuraEnabled public String formDefinitionId { get; set; }
        @AuraEnabled public String responseDataJSON { get; set; }
        @AuraEnabled public Decimal latitude { get; set; }
        @AuraEnabled public Decimal longitude { get; set; }
        @AuraEnabled public DateTime submittedDate { get; set; }
        @AuraEnabled public String targetRecordId { get; set; }
        @AuraEnabled public String objectType { get; set; }
        @AuraEnabled public DateTime modifiedDate { get; set; }
    }
    
    /**
     * DTO for media file data
     */
    public class MediaDTO {
        @AuraEnabled public String formResponseId { get; set; }
        @AuraEnabled public String fieldName { get; set; }
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public String base64Data { get; set; }
        @AuraEnabled public Decimal latitude { get; set; }
        @AuraEnabled public Decimal longitude { get; set; }
    }
    
    /**
     * Payload for metadata sync
     */
    public class MetadataPayload {
        @AuraEnabled public List<ROSE_Form_Definition__c> formDefinitions { get; set; }
        @AuraEnabled public List<ROSE_Form_Field__c> formFields { get; set; }
        
        public MetadataPayload() {
            this.formDefinitions = new List<ROSE_Form_Definition__c>();
            this.formFields = new List<ROSE_Form_Field__c>();
        }
    }
    
    /**
     * Payload for assignment sync
     */
    public class AssignmentPayload {
        @AuraEnabled public List<ROSE_Job__c> jobs { get; set; }
        @AuraEnabled public List<ROSE_Task__c> tasks { get; set; }
        @AuraEnabled public Map<String, SObject> targetRecords { get; set; }
        
        public AssignmentPayload() {
            this.jobs = new List<ROSE_Job__c>();
            this.tasks = new List<ROSE_Task__c>();
            this.targetRecords = new Map<String, SObject>();
        }
    }
    
    /**
     * Status for upload operations
     */
    public class UploadStatus {
        @AuraEnabled public Integer successCount { get; set; }
        @AuraEnabled public Integer failureCount { get; set; }
        @AuraEnabled public List<String> errors { get; set; }
        
        public UploadStatus() {
            this.successCount = 0;
            this.failureCount = 0;
            this.errors = new List<String>();
        }
    }
}
