/**
 * Service class for job and task management operations
 */
public with sharing class ROSEJobService {
    
    /**
     * Get assigned jobs for a field user
     * @param fieldUserId ID of the field user
     * @return List of assigned jobs with related tasks
     */
    @AuraEnabled(cacheable=true)
    public static List<ROSE_Job__c> getAssignedJobs(Id fieldUserId) {
        try {
            if (fieldUserId == null) {
                throw new IllegalArgumentException('Field User ID is required');
            }
            
            return [
                SELECT Id, Name, Assigned_User__c, Status__c, Due_Date__c,
                       Priority__c, Region__c, Description__c, Completed_Date__c,
                       Synced_Date__c,
                       (SELECT Id, Name, Task_Type__c, Sequence_Order__c, Status__c,
                               Target_Object__c, Target_Record__c, ROSE_Form_Definition__c,
                               Resource_URL__c, Instructions__c, Completed_Date__c
                        FROM Tasks__r
                        ORDER BY Sequence_Order__c NULLS LAST, Name)
                FROM ROSE_Job__c
                WHERE Assigned_User__c = :fieldUserId
                  AND Status__c IN ('New', 'In Progress')
                ORDER BY Priority__c, Due_Date__c NULLS LAST
                LIMIT 1000
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching assigned jobs: ' + e.getMessage());
        }
    }
    
    /**
     * Get tasks for a specific job
     * @param jobId ID of the job
     * @return List of tasks ordered by sequence
     */
    @AuraEnabled(cacheable=true)
    public static List<ROSE_Task__c> getTasksForJob(Id jobId) {
        try {
            if (jobId == null) {
                throw new IllegalArgumentException('Job ID is required');
            }
            
            return [
                SELECT Id, Name, ROSE_Job__c, Task_Type__c, Sequence_Order__c, Status__c,
                       Target_Object__c, Target_Record__c, ROSE_Form_Definition__c,
                       Resource_URL__c, Instructions__c, Completed_Date__c
                FROM ROSE_Task__c
                WHERE ROSE_Job__c = :jobId
                ORDER BY Sequence_Order__c NULLS LAST, Name
                LIMIT 1000
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching tasks: ' + e.getMessage());
        }
    }
    
    /**
     * Update task status
     * @param taskId ID of the task
     * @param status New status value
     */
    @AuraEnabled
    public static void updateTaskStatus(Id taskId, String status) {
        try {
            if (taskId == null || String.isBlank(status)) {
                throw new IllegalArgumentException('Task ID and status are required');
            }
            
            ROSE_Task__c task = new ROSE_Task__c(
                Id = taskId,
                Status__c = status
            );
            
            if (status == 'Completed') {
                task.Completed_Date__c = DateTime.now();
            }
            
            update task;
            
            // Check if all tasks in job are completed
            updateJobStatusIfComplete(task.Id);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error updating task status: ' + e.getMessage());
        }
    }
    
    /**
     * Mark job as completed
     * @param jobId ID of the job
     */
    @AuraEnabled
    public static void completeJob(Id jobId) {
        try {
            if (jobId == null) {
                throw new IllegalArgumentException('Job ID is required');
            }
            
            ROSE_Job__c job = new ROSE_Job__c(
                Id = jobId,
                Status__c = 'Completed',
                Completed_Date__c = DateTime.now()
            );
            
            update job;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error completing job: ' + e.getMessage());
        }
    }
    
    /**
     * Check if all tasks in a job are completed and update job status
     * @param taskId ID of a task in the job
     */
    private static void updateJobStatusIfComplete(Id taskId) {
        try {
            // Get the job for this task
            ROSE_Task__c task = [SELECT ROSE_Job__c FROM ROSE_Task__c WHERE Id = :taskId LIMIT 1];
            
            // Get all tasks for the job
            List<ROSE_Task__c> allTasks = [
                SELECT Status__c
                FROM ROSE_Task__c
                WHERE ROSE_Job__c = :task.ROSE_Job__c
            ];
            
            // Check if all tasks are completed
            Boolean allCompleted = true;
            for (ROSE_Task__c t : allTasks) {
                if (t.Status__c != 'Completed') {
                    allCompleted = false;
                    break;
                }
            }
            
            // Update job status
            if (allCompleted) {
                completeJob(task.ROSE_Job__c);
            } else {
                // Update to In Progress if not already
                ROSE_Job__c job = [SELECT Status__c FROM ROSE_Job__c WHERE Id = :task.ROSE_Job__c LIMIT 1];
                if (job.Status__c == 'New') {
                    job.Status__c = 'In Progress';
                    update job;
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error updating job status: ' + e.getMessage());
        }
    }
}
