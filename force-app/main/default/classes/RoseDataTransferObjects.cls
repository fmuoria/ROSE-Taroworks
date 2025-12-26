/**
 * @description Data Transfer Objects for ROSE sync operations
 * @author ROSE Team
 * @date 2025
 */
public with sharing class RoseDataTransferObjects {
    
    /**
     * Request payload for sync operation
     */
    public class SyncRequest {
        @AuraEnabled public String userId { get; set; }
        @AuraEnabled public DateTime lastSyncTime { get; set; }
        @AuraEnabled public List<FormResponseDTO> pendingResponses { get; set; }
        @AuraEnabled public List<MediaDTO> pendingMedia { get; set; }
        
        public SyncRequest() {
            this.pendingResponses = new List<FormResponseDTO>();
            this.pendingMedia = new List<MediaDTO>();
        }
    }
    
    /**
     * Result of sync operation
     */
    public class SyncResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public MetadataPayload metadata { get; set; }
        @AuraEnabled public AssignmentPayload assignments { get; set; }
        @AuraEnabled public List<UploadStatus> uploadStatuses { get; set; }
        @AuraEnabled public DateTime syncTime { get; set; }
        @AuraEnabled public Integer recordsUp { get; set; }
        @AuraEnabled public Integer recordsDown { get; set; }
        
        public SyncResult() {
            this.success = false;
            this.uploadStatuses = new List<UploadStatus>();
            this.syncTime = DateTime.now();
            this.recordsUp = 0;
            this.recordsDown = 0;
        }
    }
    
    /**
     * Form response data transfer object
     */
    public class FormResponseDTO {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String taskId { get; set; }
        @AuraEnabled public String formDefinitionId { get; set; }
        @AuraEnabled public String responseData { get; set; }
        @AuraEnabled public String targetRecordId { get; set; }
        @AuraEnabled public Decimal gpsLatitude { get; set; }
        @AuraEnabled public Decimal gpsLongitude { get; set; }
        @AuraEnabled public DateTime submittedDate { get; set; }
        @AuraEnabled public DateTime lastModifiedDate { get; set; }
    }
    
    /**
     * Media file data transfer object
     */
    public class MediaDTO {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String formResponseId { get; set; }
        @AuraEnabled public String fieldName { get; set; }
        @AuraEnabled public String fileName { get; set; }
        @AuraEnabled public String fileData { get; set; } // Base64 encoded
        @AuraEnabled public Decimal gpsLatitude { get; set; }
        @AuraEnabled public Decimal gpsLongitude { get; set; }
        @AuraEnabled public DateTime capturedDate { get; set; }
    }
    
    /**
     * Metadata payload including form definitions and fields
     */
    public class MetadataPayload {
        @AuraEnabled public List<FormDefinitionDTO> formDefinitions { get; set; }
        @AuraEnabled public Map<String, List<FormFieldDTO>> formFields { get; set; }
        
        public MetadataPayload() {
            this.formDefinitions = new List<FormDefinitionDTO>();
            this.formFields = new Map<String, List<FormFieldDTO>>();
        }
    }
    
    /**
     * Form definition data transfer object
     */
    public class FormDefinitionDTO {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String targetObject { get; set; }
        @AuraEnabled public String version { get; set; }
        @AuraEnabled public Boolean active { get; set; }
        @AuraEnabled public String description { get; set; }
    }
    
    /**
     * Form field data transfer object
     */
    public class FormFieldDTO {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String fieldApiName { get; set; }
        @AuraEnabled public String fieldLabel { get; set; }
        @AuraEnabled public String fieldType { get; set; }
        @AuraEnabled public Boolean required { get; set; }
        @AuraEnabled public Integer displayOrder { get; set; }
        @AuraEnabled public String validationRule { get; set; }
        @AuraEnabled public String conditionalLogic { get; set; }
        @AuraEnabled public String picklistValues { get; set; }
        @AuraEnabled public String defaultValue { get; set; }
        @AuraEnabled public String helpText { get; set; }
    }
    
    /**
     * Assignment payload including jobs and tasks
     */
    public class AssignmentPayload {
        @AuraEnabled public List<JobDTO> jobs { get; set; }
        @AuraEnabled public Map<String, List<TaskDTO>> tasks { get; set; }
        
        public AssignmentPayload() {
            this.jobs = new List<JobDTO>();
            this.tasks = new Map<String, List<TaskDTO>>();
        }
    }
    
    /**
     * Job data transfer object
     */
    public class JobDTO {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String assignedUserId { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Date dueDate { get; set; }
        @AuraEnabled public String priority { get; set; }
        @AuraEnabled public String region { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public DateTime completedDate { get; set; }
        @AuraEnabled public DateTime lastModifiedDate { get; set; }
    }
    
    /**
     * Task data transfer object
     */
    public class TaskDTO {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String jobId { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public String taskType { get; set; }
        @AuraEnabled public Integer sequenceOrder { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String targetObject { get; set; }
        @AuraEnabled public String targetRecordId { get; set; }
        @AuraEnabled public String formDefinitionId { get; set; }
        @AuraEnabled public String resourceUrl { get; set; }
        @AuraEnabled public String instructions { get; set; }
        @AuraEnabled public DateTime completedDate { get; set; }
        @AuraEnabled public DateTime lastModifiedDate { get; set; }
    }
    
    /**
     * Upload status for individual record
     */
    public class UploadStatus {
        @AuraEnabled public String id { get; set; }
        @AuraEnabled public String recordType { get; set; } // FormResponse, Media
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public String serverId { get; set; } // Server-side ID after upload
    }
}
