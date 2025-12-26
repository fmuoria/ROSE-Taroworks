/**
 * @description Main sync orchestrator service for ROSE
 * @author ROSE Team
 * @date 2025
 */
public with sharing class RoseSyncService {
    
    /**
     * Perform full sync operation
     * @param userId The user ID (Field_User__c ID)
     * @param request The sync request with pending data
     * @return Sync result with downloaded data and upload statuses
     */
    @AuraEnabled
    public static RoseDataTransferObjects.SyncResult performSync(
        String userId,
        RoseDataTransferObjects.SyncRequest request
    ) {
        RoseDataTransferObjects.SyncResult result = new RoseDataTransferObjects.SyncResult();
        DateTime syncStartTime = DateTime.now();
        
        try {
            // Phase 1: Validate user
            if (String.isBlank(userId)) {
                throw new IllegalArgumentException('User ID cannot be blank');
            }
            
            // Phase 2: Sync metadata (form definitions and fields)
            result.metadata = syncMetadata(request.lastSyncTime);
            
            // Phase 3: Sync assignments (jobs and tasks)
            result.assignments = syncAssignments(userId, request.lastSyncTime);
            
            // Phase 4: Upload form responses
            if (request.pendingResponses != null && !request.pendingResponses.isEmpty()) {
                List<RoseDataTransferObjects.UploadStatus> responseStatuses = 
                    uploadFormResponses(request.pendingResponses);
                result.uploadStatuses.addAll(responseStatuses);
                result.recordsUp += responseStatuses.size();
            }
            
            // Phase 5: Upload media
            if (request.pendingMedia != null && !request.pendingMedia.isEmpty()) {
                List<RoseDataTransferObjects.UploadStatus> mediaStatuses = 
                    uploadMedia(request.pendingMedia);
                result.uploadStatuses.addAll(mediaStatuses);
                result.recordsUp += mediaStatuses.size();
            }
            
            // Phase 6: Count downloaded records
            result.recordsDown = countDownloadedRecords(result.metadata, result.assignments);
            
            // Phase 7: Update last sync time for user
            updateLastSyncTime(userId, syncStartTime);
            
            // Phase 8: Log sync
            logSync(userId, result, syncStartTime);
            
            result.success = true;
            result.message = 'Sync completed successfully';
            result.syncTime = syncStartTime;
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Sync failed: ' + e.getMessage();
            logSyncError(userId, e, syncStartTime);
        }
        
        return result;
    }
    
    /**
     * Sync form metadata (definitions and fields)
     * @param lastSync Last sync time (null for full sync)
     * @return Metadata payload with forms and fields
     */
    public static RoseDataTransferObjects.MetadataPayload syncMetadata(DateTime lastSync) {
        RoseDataTransferObjects.MetadataPayload payload = 
            new RoseDataTransferObjects.MetadataPayload();
        
        // Get active form definitions
        List<Form_Definition__c> formDefs = RoseFormService.getActiveFormDefinitions();
        
        for (Form_Definition__c formDef : formDefs) {
            RoseDataTransferObjects.FormDefinitionDTO dto = 
                new RoseDataTransferObjects.FormDefinitionDTO();
            dto.id = formDef.Id;
            dto.name = formDef.Name;
            dto.targetObject = formDef.Target_Object__c;
            dto.version = formDef.Version__c;
            dto.active = formDef.Active__c;
            dto.description = formDef.Description__c;
            
            payload.formDefinitions.add(dto);
            
            // Get form fields
            List<Form_Field__c> fields = RoseFormService.getFormFields(formDef.Id);
            List<RoseDataTransferObjects.FormFieldDTO> fieldDTOs = 
                new List<RoseDataTransferObjects.FormFieldDTO>();
            
            for (Form_Field__c field : fields) {
                RoseDataTransferObjects.FormFieldDTO fieldDTO = 
                    new RoseDataTransferObjects.FormFieldDTO();
                fieldDTO.id = field.Id;
                fieldDTO.fieldApiName = field.Field_API_Name__c;
                fieldDTO.fieldLabel = field.Field_Label__c;
                fieldDTO.fieldType = field.Field_Type__c;
                fieldDTO.required = field.Required__c;
                fieldDTO.displayOrder = Integer.valueOf(field.Display_Order__c);
                fieldDTO.validationRule = field.Validation_Rule__c;
                fieldDTO.conditionalLogic = field.Conditional_Logic__c;
                fieldDTO.picklistValues = field.Picklist_Values__c;
                fieldDTO.defaultValue = field.Default_Value__c;
                fieldDTO.helpText = field.Help_Text__c;
                
                fieldDTOs.add(fieldDTO);
            }
            
            payload.formFields.put(formDef.Id, fieldDTOs);
        }
        
        return payload;
    }
    
    /**
     * Sync job assignments for user
     * @param userId Field User ID
     * @param lastSync Last sync time (null for full sync)
     * @return Assignment payload with jobs and tasks
     */
    public static RoseDataTransferObjects.AssignmentPayload syncAssignments(
        String userId,
        DateTime lastSync
    ) {
        RoseDataTransferObjects.AssignmentPayload payload = 
            new RoseDataTransferObjects.AssignmentPayload();
        
        // Get assigned jobs
        List<Job__c> jobs = RoseJobService.getAssignedJobs(userId);
        
        for (Job__c job : jobs) {
            RoseDataTransferObjects.JobDTO jobDTO = new RoseDataTransferObjects.JobDTO();
            jobDTO.id = job.Id;
            jobDTO.name = job.Name;
            jobDTO.assignedUserId = job.Assigned_User__c;
            jobDTO.status = job.Status__c;
            jobDTO.dueDate = job.Due_Date__c;
            jobDTO.priority = job.Priority__c;
            jobDTO.region = job.Region__c;
            jobDTO.description = job.Description__c;
            jobDTO.completedDate = job.Completed_Date__c;
            jobDTO.lastModifiedDate = job.LastModifiedDate;
            
            payload.jobs.add(jobDTO);
            
            // Get tasks for job
            List<Task__c> tasks = RoseJobService.getTasksForJob(job.Id);
            List<RoseDataTransferObjects.TaskDTO> taskDTOs = 
                new List<RoseDataTransferObjects.TaskDTO>();
            
            for (Task__c task : tasks) {
                RoseDataTransferObjects.TaskDTO taskDTO = new RoseDataTransferObjects.TaskDTO();
                taskDTO.id = task.Id;
                taskDTO.jobId = task.Job__c;
                taskDTO.name = task.Name;
                taskDTO.taskType = task.Task_Type__c;
                taskDTO.sequenceOrder = Integer.valueOf(task.Sequence_Order__c);
                taskDTO.status = task.Status__c;
                taskDTO.targetObject = task.Target_Object__c;
                taskDTO.targetRecordId = task.Target_Record__c;
                taskDTO.formDefinitionId = task.Form_Definition__c;
                taskDTO.resourceUrl = task.Resource_URL__c;
                taskDTO.instructions = task.Instructions__c;
                taskDTO.completedDate = task.Completed_Date__c;
                taskDTO.lastModifiedDate = task.LastModifiedDate;
                
                taskDTOs.add(taskDTO);
            }
            
            payload.tasks.put(job.Id, taskDTOs);
        }
        
        return payload;
    }
    
    /**
     * Upload form responses from device
     * @param responses List of form response DTOs
     * @return List of upload statuses
     */
    public static List<RoseDataTransferObjects.UploadStatus> uploadFormResponses(
        List<RoseDataTransferObjects.FormResponseDTO> responses
    ) {
        List<RoseDataTransferObjects.UploadStatus> statuses = 
            new List<RoseDataTransferObjects.UploadStatus>();
        
        List<Form_Response__c> responsesToUpsert = new List<Form_Response__c>();
        
        for (RoseDataTransferObjects.FormResponseDTO dto : responses) {
            Form_Response__c response = new Form_Response__c();
            
            if (String.isNotBlank(dto.id)) {
                response.Id = dto.id;
            }
            
            response.Task__c = dto.taskId;
            response.Form_Definition__c = dto.formDefinitionId;
            response.Response_Data__c = dto.responseData;
            response.Target_Record__c = dto.targetRecordId;
            response.GPS_Latitude__c = dto.gpsLatitude;
            response.GPS_Longitude__c = dto.gpsLongitude;
            response.Submitted_Date__c = dto.submittedDate;
            response.Synced__c = true;
            response.Sync_Status__c = 'Success';
            
            responsesToUpsert.add(response);
        }
        
        try {
            upsert responsesToUpsert;
            
            for (Integer i = 0; i < responsesToUpsert.size(); i++) {
                RoseDataTransferObjects.UploadStatus status = 
                    new RoseDataTransferObjects.UploadStatus();
                status.id = responses[i].id;
                status.recordType = 'FormResponse';
                status.success = true;
                status.message = 'Upload successful';
                status.serverId = responsesToUpsert[i].Id;
                statuses.add(status);
                
                // Process form response to create target record
                try {
                    RoseFormService.processFormResponse(responsesToUpsert[i]);
                } catch (Exception e) {
                    // Log but don't fail the sync
                    System.debug('Error processing form response: ' + e.getMessage());
                }
            }
        } catch (Exception e) {
            for (RoseDataTransferObjects.FormResponseDTO dto : responses) {
                RoseDataTransferObjects.UploadStatus status = 
                    new RoseDataTransferObjects.UploadStatus();
                status.id = dto.id;
                status.recordType = 'FormResponse';
                status.success = false;
                status.message = e.getMessage();
                statuses.add(status);
            }
        }
        
        return statuses;
    }
    
    /**
     * Upload media files from device
     * @param mediaFiles List of media DTOs
     * @return List of upload statuses
     */
    public static List<RoseDataTransferObjects.UploadStatus> uploadMedia(
        List<RoseDataTransferObjects.MediaDTO> mediaFiles
    ) {
        List<RoseDataTransferObjects.UploadStatus> statuses = 
            new List<RoseDataTransferObjects.UploadStatus>();
        
        for (RoseDataTransferObjects.MediaDTO mediaDTO : mediaFiles) {
            RoseDataTransferObjects.UploadStatus status = 
                new RoseDataTransferObjects.UploadStatus();
            status.id = mediaDTO.id;
            status.recordType = 'Media';
            
            try {
                String mediaId = RoseMediaService.uploadMediaFromDTO(mediaDTO);
                status.success = true;
                status.message = 'Media upload successful';
                status.serverId = mediaId;
            } catch (Exception e) {
                status.success = false;
                status.message = e.getMessage();
            }
            
            statuses.add(status);
        }
        
        return statuses;
    }
    
    /**
     * Resolve sync conflicts (placeholder for future implementation)
     * @param responses Form responses that may have conflicts
     * @return List of resolved responses
     */
    public static List<RoseDataTransferObjects.FormResponseDTO> resolveConflicts(
        List<RoseDataTransferObjects.FormResponseDTO> responses
    ) {
        // Placeholder: Implement timestamp-based conflict resolution
        // For now, last write wins (server timestamp)
        return responses;
    }
    
    /**
     * Cleanup synced jobs from device (mark as synced)
     * @param userId Field User ID
     */
    public static void cleanupSyncedJobs(String userId) {
        List<Job__c> completedJobs = [
            SELECT Id
            FROM Job__c
            WHERE Assigned_User__c = :userId
                AND Status__c = 'Completed'
                AND Synced_Date__c = null
        ];
        
        for (Job__c job : completedJobs) {
            job.Status__c = 'Synced';
            job.Synced_Date__c = DateTime.now();
        }
        
        if (!completedJobs.isEmpty()) {
            update completedJobs;
        }
    }
    
    /**
     * Log successful sync event
     * @param userId Field User ID
     * @param result Sync result
     * @param startTime Sync start time
     */
    public static void logSync(
        String userId,
        RoseDataTransferObjects.SyncResult result,
        DateTime startTime
    ) {
        Sync_Log__c log = new Sync_Log__c(
            Field_User__c = userId,
            Sync_Type__c = 'Full',
            Start_Time__c = startTime,
            End_Time__c = DateTime.now(),
            Records_Up__c = result.recordsUp,
            Records_Down__c = result.recordsDown,
            Status__c = 'Success'
        );
        
        insert log;
    }
    
    /**
     * Log sync error
     * @param userId Field User ID
     * @param error The exception that occurred
     * @param startTime Sync start time
     */
    private static void logSyncError(String userId, Exception error, DateTime startTime) {
        Sync_Log__c log = new Sync_Log__c(
            Field_User__c = userId,
            Sync_Type__c = 'Full',
            Start_Time__c = startTime,
            End_Time__c = DateTime.now(),
            Records_Up__c = 0,
            Records_Down__c = 0,
            Status__c = 'Failed',
            Error_Details__c = error.getMessage() + '\n' + error.getStackTraceString()
        );
        
        insert log;
    }
    
    /**
     * Update last sync time for field user
     * @param userId Field User ID
     * @param syncTime Sync time to set
     */
    private static void updateLastSyncTime(String userId, DateTime syncTime) {
        Field_User__c user = new Field_User__c(
            Id = userId,
            Last_Sync__c = syncTime
        );
        
        update user;
    }
    
    /**
     * Count downloaded records
     * @param metadata Metadata payload
     * @param assignments Assignment payload
     * @return Total count of downloaded records
     */
    private static Integer countDownloadedRecords(
        RoseDataTransferObjects.MetadataPayload metadata,
        RoseDataTransferObjects.AssignmentPayload assignments
    ) {
        Integer count = 0;
        
        if (metadata != null && metadata.formDefinitions != null) {
            count += metadata.formDefinitions.size();
        }
        
        if (assignments != null && assignments.jobs != null) {
            count += assignments.jobs.size();
        }
        
        return count;
    }
}
