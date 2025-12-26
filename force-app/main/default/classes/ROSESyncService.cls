/**
 * Main sync orchestrator service
 * Handles bidirectional sync between mobile devices and Salesforce
 */
public with sharing class ROSESyncService {
    
    /**
     * Perform full sync operation
     * @param userId Current user ID
     * @param syncRequestJSON JSON string of sync request
     * @return SyncResult with metadata, assignments, and upload status
     */
    @AuraEnabled
    public static ROSEDataTransferObjects.SyncResult performSync(String userId, String syncRequestJSON) {
        ROSEDataTransferObjects.SyncResult result = new ROSEDataTransferObjects.SyncResult();
        DateTime startTime = DateTime.now();
        
        try {
            // Parse sync request
            ROSEDataTransferObjects.SyncRequest request = 
                (ROSEDataTransferObjects.SyncRequest) JSON.deserialize(
                    syncRequestJSON, 
                    ROSEDataTransferObjects.SyncRequest.class
                );
            
            // Find field user
            List<ROSE_Field_User__c> fieldUsers = [
                SELECT Id FROM ROSE_Field_User__c 
                WHERE User__c = :userId 
                LIMIT 1
            ];
            
            if (fieldUsers.isEmpty()) {
                throw new IllegalArgumentException('Field user not found for user: ' + userId);
            }
            
            String fieldUserId = fieldUsers[0].Id;
            
            // Phase 1: Upload form responses
            if (request.formResponses != null && !request.formResponses.isEmpty()) {
                result.uploadStatus = uploadFormResponses(request.formResponses);
            } else {
                result.uploadStatus = new ROSEDataTransferObjects.UploadStatus();
            }
            
            // Phase 2: Upload media files
            if (request.mediaFiles != null && !request.mediaFiles.isEmpty()) {
                uploadMedia(request.mediaFiles);
            }
            
            // Phase 3: Sync metadata
            result.metadata = syncMetadata(request.lastMetadataSync);
            
            // Phase 4: Sync assignments
            result.assignments = syncAssignments(fieldUserId, request.lastAssignmentSync);
            
            // Phase 5: Resolve conflicts
            result.conflicts = resolveConflicts(request.formResponses);
            
            // Phase 6: Cleanup synced jobs
            cleanupSyncedJobs(fieldUserId);
            
            result.success = true;
            result.timestamp = DateTime.now();
            
            // Log sync
            logSync(fieldUserId, result, startTime);
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
            System.debug(LoggingLevel.ERROR, 'Sync error: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        
        return result;
    }
    
    /**
     * Sync metadata (form definitions and fields)
     * @param lastSync Last metadata sync timestamp
     * @return MetadataPayload with forms and fields
     */
    private static ROSEDataTransferObjects.MetadataPayload syncMetadata(DateTime lastSync) {
        ROSEDataTransferObjects.MetadataPayload payload = new ROSEDataTransferObjects.MetadataPayload();
        
        try {
            // Get active form definitions
            String query = 'SELECT Id, Name, Target_Object__c, Version__c, Active__c, Description__c ' +
                          'FROM ROSE_Form_Definition__c WHERE Active__c = true';
            
            if (lastSync != null) {
                query += ' AND LastModifiedDate > :lastSync';
            }
            
            payload.formDefinitions = Database.query(query + ' LIMIT 1000');
            
            // Get form fields for active forms
            if (!payload.formDefinitions.isEmpty()) {
                Set<Id> formDefIds = new Set<Id>();
                for (ROSE_Form_Definition__c fd : payload.formDefinitions) {
                    formDefIds.add(fd.Id);
                }
                
                payload.formFields = [
                    SELECT Id, Name, ROSE_Form_Definition__c, Field_API_Name__c, Field_Label__c,
                           Field_Type__c, Required__c, Display_Order__c, Validation_Rule__c,
                           Conditional_Logic__c, Picklist_Values__c, Default_Value__c, Help_Text__c
                    FROM ROSE_Form_Field__c
                    WHERE ROSE_Form_Definition__c IN :formDefIds
                    ORDER BY ROSE_Form_Definition__c, Display_Order__c NULLS LAST
                    LIMIT 10000
                ];
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error syncing metadata: ' + e.getMessage());
        }
        
        return payload;
    }
    
    /**
     * Sync job and task assignments
     * @param fieldUserId Field user ID
     * @param lastSync Last assignment sync timestamp
     * @return AssignmentPayload with jobs, tasks, and target records
     */
    private static ROSEDataTransferObjects.AssignmentPayload syncAssignments(String fieldUserId, DateTime lastSync) {
        ROSEDataTransferObjects.AssignmentPayload payload = new ROSEDataTransferObjects.AssignmentPayload();
        
        try {
            // Get assigned jobs
            String jobQuery = 'SELECT Id, Name, Assigned_User__c, Status__c, Due_Date__c, ' +
                             'Priority__c, Region__c, Description__c, Completed_Date__c, Synced_Date__c ' +
                             'FROM ROSE_Job__c WHERE Assigned_User__c = :fieldUserId ' +
                             'AND Status__c IN (\'New\', \'In Progress\')';
            
            if (lastSync != null) {
                jobQuery += ' AND LastModifiedDate > :lastSync';
            }
            
            payload.jobs = Database.query(jobQuery + ' LIMIT 1000');
            
            // Get tasks for assigned jobs
            if (!payload.jobs.isEmpty()) {
                Set<Id> jobIds = new Set<Id>();
                for (ROSE_Job__c job : payload.jobs) {
                    jobIds.add(job.Id);
                }
                
                payload.tasks = [
                    SELECT Id, Name, ROSE_Job__c, Task_Type__c, Sequence_Order__c, Status__c,
                           Target_Object__c, Target_Record__c, ROSE_Form_Definition__c,
                           Resource_URL__c, Instructions__c, Completed_Date__c
                    FROM ROSE_Task__c
                    WHERE ROSE_Job__c IN :jobIds
                    ORDER BY ROSE_Job__c, Sequence_Order__c NULLS LAST
                    LIMIT 10000
                ];
                
                // Get target records for "View Data" tasks
                Set<String> targetRecordIds = new Set<String>();
                for (ROSE_Task__c task : payload.tasks) {
                    if (task.Task_Type__c == 'View Data' && String.isNotBlank(task.Target_Record__c)) {
                        targetRecordIds.add(task.Target_Record__c);
                    }
                }
                
                if (!targetRecordIds.isEmpty()) {
                    payload.targetRecords = fetchTargetRecords(targetRecordIds);
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error syncing assignments: ' + e.getMessage());
        }
        
        return payload;
    }
    
    /**
     * Upload form responses and create target records
     * @param responses List of form response DTOs
     * @return UploadStatus with counts and errors
     */
    private static ROSEDataTransferObjects.UploadStatus uploadFormResponses(List<ROSEDataTransferObjects.FormResponseDTO> responses) {
        ROSEDataTransferObjects.UploadStatus status = new ROSEDataTransferObjects.UploadStatus();
        
        List<ROSE_Form_Response__c> formResponses = new List<ROSE_Form_Response__c>();
        Map<String, ROSEDataTransferObjects.FormResponseDTO> responseMap = new Map<String, ROSEDataTransferObjects.FormResponseDTO>();
        
        try {
            for (ROSEDataTransferObjects.FormResponseDTO dto : responses) {
                ROSE_Form_Response__c response = new ROSE_Form_Response__c(
                    ROSE_Task__c = dto.taskId,
                    ROSE_Form_Definition__c = dto.formDefinitionId,
                    Response_Data__c = dto.responseDataJSON,
                    GPS_Latitude__c = dto.latitude,
                    GPS_Longitude__c = dto.longitude,
                    Submitted_Date__c = dto.submittedDate,
                    Synced__c = true,
                    Sync_Status__c = 'Pending'
                );
                
                formResponses.add(response);
                String tempKey = 'temp_' + formResponses.size();
                responseMap.put(tempKey, dto);
            }
            
            // Insert form responses
            Database.SaveResult[] results = Database.insert(formResponses, false);
            
            Integer index = 0;
            for (Database.SaveResult result : results) {
                if (result.isSuccess()) {
                    try {
                        // Process form response to create/update target record
                        Id targetRecordId = ROSEFormService.processFormResponse(formResponses[index]);
                        
                        // Update form response with target record ID
                        formResponses[index].Target_Record__c = targetRecordId;
                        formResponses[index].Sync_Status__c = 'Success';
                        
                        // Update task status
                        if (formResponses[index].ROSE_Task__c != null) {
                            ROSEJobService.updateTaskStatus(formResponses[index].ROSE_Task__c, 'Completed');
                        }
                        
                        status.successCount++;
                    } catch (Exception e) {
                        formResponses[index].Sync_Status__c = 'Failed';
                        formResponses[index].Error_Message__c = e.getMessage();
                        status.failureCount++;
                        status.errors.add('Error processing response: ' + e.getMessage());
                    }
                } else {
                    status.failureCount++;
                    status.errors.add('Error inserting response: ' + result.getErrors()[0].getMessage());
                }
                index++;
            }
            
            // Update form responses with target record IDs and sync status
            update formResponses;
            
        } catch (Exception e) {
            status.errors.add('Upload error: ' + e.getMessage());
        }
        
        return status;
    }
    
    /**
     * Upload media files
     * @param mediaFiles List of media DTOs
     * @return UploadStatus with counts and errors
     */
    private static ROSEDataTransferObjects.UploadStatus uploadMedia(List<ROSEDataTransferObjects.MediaDTO> mediaFiles) {
        ROSEDataTransferObjects.UploadStatus status = new ROSEDataTransferObjects.UploadStatus();
        
        try {
            for (ROSEDataTransferObjects.MediaDTO media : mediaFiles) {
                try {
                    ROSEMediaService.uploadPhoto(
                        media.base64Data,
                        media.formResponseId,
                        media.fieldName,
                        media.fileName
                    );
                    status.successCount++;
                } catch (Exception e) {
                    status.failureCount++;
                    status.errors.add('Error uploading ' + media.fileName + ': ' + e.getMessage());
                }
            }
        } catch (Exception e) {
            status.errors.add('Media upload error: ' + e.getMessage());
        }
        
        return status;
    }
    
    /**
     * Resolve sync conflicts
     * @param responses List of form responses
     * @return List of conflict records
     */
    private static List<ROSE_Conflict_Queue__c> resolveConflicts(List<ROSEDataTransferObjects.FormResponseDTO> responses) {
        List<ROSE_Conflict_Queue__c> conflicts = new List<ROSE_Conflict_Queue__c>();
        
        try {
            if (responses == null || responses.isEmpty()) {
                return conflicts;
            }
            
            // Collect target record IDs
            Set<String> targetRecordIds = new Set<String>();
            for (ROSEDataTransferObjects.FormResponseDTO response : responses) {
                if (String.isNotBlank(response.targetRecordId)) {
                    targetRecordIds.add(response.targetRecordId);
                }
            }
            
            if (targetRecordIds.isEmpty()) {
                return conflicts;
            }
            
            // Check for conflicts (server modified after device)
            // This would require dynamic SOQL based on object type
            // For now, return empty list - conflicts handled at object level
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error resolving conflicts: ' + e.getMessage());
        }
        
        return conflicts;
    }
    
    /**
     * Cleanup completed and synced jobs
     * @param fieldUserId Field user ID
     */
    private static void cleanupSyncedJobs(String fieldUserId) {
        try {
            // Find completed jobs where all responses are synced
            List<ROSE_Job__c> completedJobs = [
                SELECT Id, Status__c
                FROM ROSE_Job__c
                WHERE Assigned_User__c = :fieldUserId
                  AND Status__c = 'Completed'
                  AND Synced_Date__c = null
                LIMIT 200
            ];
            
            for (ROSE_Job__c job : completedJobs) {
                // Check if all form responses for this job are synced
                Integer unsyncedCount = [
                    SELECT COUNT()
                    FROM ROSE_Form_Response__c
                    WHERE ROSE_Task__r.ROSE_Job__c = :job.Id
                      AND Synced__c = false
                ];
                
                if (unsyncedCount == 0) {
                    job.Status__c = 'Synced';
                    job.Synced_Date__c = DateTime.now();
                }
            }
            
            if (!completedJobs.isEmpty()) {
                update completedJobs;
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error cleaning up jobs: ' + e.getMessage());
        }
    }
    
    /**
     * Log sync operation
     * @param fieldUserId Field user ID
     * @param result Sync result
     * @param startTime Sync start time
     */
    private static void logSync(String fieldUserId, ROSEDataTransferObjects.SyncResult result, DateTime startTime) {
        try {
            ROSE_Sync_Log__c log = new ROSE_Sync_Log__c(
                ROSE_Field_User__c = fieldUserId,
                Sync_Type__c = 'Full',
                Start_Time__c = startTime,
                End_Time__c = DateTime.now(),
                Status__c = result.success ? 'Success' : 'Failed'
            );
            
            if (result.uploadStatus != null) {
                log.Records_Up__c = result.uploadStatus.successCount;
            }
            
            if (result.assignments != null && result.assignments.jobs != null) {
                log.Records_Down__c = result.assignments.jobs.size();
            }
            
            if (!result.success && String.isNotBlank(result.errorMessage)) {
                log.Error_Details__c = result.errorMessage;
            }
            
            insert log;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error logging sync: ' + e.getMessage());
        }
    }
    
    /**
     * Fetch target records dynamically
     * @param recordIds Set of record IDs
     * @return Map of record IDs to SObjects
     */
    private static Map<String, SObject> fetchTargetRecords(Set<String> recordIds) {
        Map<String, SObject> records = new Map<String, SObject>();
        
        try {
            // Group IDs by object type
            Map<String, List<String>> idsByType = new Map<String, List<String>>();
            
            for (String recordId : recordIds) {
                String objectType = recordId.substring(0, 3);
                if (!idsByType.containsKey(objectType)) {
                    idsByType.put(objectType, new List<String>());
                }
                idsByType.get(objectType).add(recordId);
            }
            
            // Query records by type (simplified - would need more robust implementation)
            for (String recordId : recordIds) {
                try {
                    SObject record = Database.query('SELECT Id, Name FROM Contact WHERE Id = :recordId LIMIT 1');
                    records.put(recordId, record);
                } catch (Exception e) {
                    System.debug(LoggingLevel.WARN, 'Could not fetch record: ' + recordId);
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error fetching target records: ' + e.getMessage());
        }
        
        return records;
    }
}
