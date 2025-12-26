/**
 * @description Service class for Job and Task management operations
 * @author ROSE Team
 * @date 2025
 */
public with sharing class RoseJobService {
    
    /**
     * Get jobs assigned to a specific field user
     * @param fieldUserId The ID of the Field_User__c record
     * @return List of jobs assigned to the user
     */
    public static List<Job__c> getAssignedJobs(Id fieldUserId) {
        if (fieldUserId == null) {
            throw new IllegalArgumentException('Field User ID cannot be null');
        }
        
        return [
            SELECT Id, Name, Assigned_User__c, Status__c, Due_Date__c, Priority__c,
                   Region__c, Description__c, Completed_Date__c, Synced_Date__c,
                   LastModifiedDate
            FROM Job__c
            WHERE Assigned_User__c = :fieldUserId
                AND Status__c != 'Synced'
            ORDER BY Priority__c DESC, Due_Date__c ASC
            LIMIT 1000
        ];
    }
    
    /**
     * Get tasks for a specific job
     * @param jobId The ID of the Job__c record
     * @return List of tasks for the job
     */
    public static List<Task__c> getTasksForJob(Id jobId) {
        if (jobId == null) {
            throw new IllegalArgumentException('Job ID cannot be null');
        }
        
        return [
            SELECT Id, Name, Job__c, Task_Type__c, Sequence_Order__c, Status__c,
                   Target_Object__c, Target_Record__c, Form_Definition__c,
                   Resource_URL__c, Instructions__c, Completed_Date__c, LastModifiedDate
            FROM Task__c
            WHERE Job__c = :jobId
            ORDER BY Sequence_Order__c ASC
            LIMIT 1000
        ];
    }
    
    /**
     * Update task status
     * @param taskId The ID of the Task__c record
     * @param status The new status value
     */
    public static void updateTaskStatus(Id taskId, String status) {
        if (taskId == null) {
            throw new IllegalArgumentException('Task ID cannot be null');
        }
        if (String.isBlank(status)) {
            throw new IllegalArgumentException('Status cannot be blank');
        }
        
        Task__c task = new Task__c(Id = taskId, Status__c = status);
        
        if (status == 'Completed') {
            task.Completed_Date__c = DateTime.now();
        }
        
        update task;
        
        // Check if all tasks in the job are completed
        updateJobStatusIfAllTasksCompleted(task.Id);
    }
    
    /**
     * Mark a job as completed
     * @param jobId The ID of the Job__c record
     */
    public static void completeJob(Id jobId) {
        if (jobId == null) {
            throw new IllegalArgumentException('Job ID cannot be null');
        }
        
        Job__c job = new Job__c(
            Id = jobId,
            Status__c = 'Completed',
            Completed_Date__c = DateTime.now()
        );
        
        update job;
    }
    
    /**
     * Helper method to update job status when all tasks are completed
     * @param taskId A task ID to check its parent job
     */
    private static void updateJobStatusIfAllTasksCompleted(Id taskId) {
        Task__c task = [SELECT Job__c FROM Task__c WHERE Id = :taskId LIMIT 1];
        
        List<Task__c> incompleteTasks = [
            SELECT Id
            FROM Task__c
            WHERE Job__c = :task.Job__c
                AND Status__c != 'Completed'
            LIMIT 1
        ];
        
        if (incompleteTasks.isEmpty()) {
            completeJob(task.Job__c);
        }
    }
    
    /**
     * Get job with task count
     * @param fieldUserId The ID of the Field_User__c record
     * @return Map of job IDs to task counts
     */
    public static Map<Id, Integer> getJobTaskCounts(Id fieldUserId) {
        if (fieldUserId == null) {
            throw new IllegalArgumentException('Field User ID cannot be null');
        }
        
        Map<Id, Integer> jobTaskCounts = new Map<Id, Integer>();
        Map<Id, Integer> jobCompletedCounts = new Map<Id, Integer>();
        
        List<Job__c> jobs = getAssignedJobs(fieldUserId);
        Set<Id> jobIds = new Set<Id>();
        
        for (Job__c job : jobs) {
            jobIds.add(job.Id);
            jobTaskCounts.put(job.Id, 0);
            jobCompletedCounts.put(job.Id, 0);
        }
        
        // Count all tasks
        for (AggregateResult ar : [
            SELECT Job__c, COUNT(Id) cnt
            FROM Task__c
            WHERE Job__c IN :jobIds
            GROUP BY Job__c
        ]) {
            jobTaskCounts.put((Id)ar.get('Job__c'), (Integer)ar.get('cnt'));
        }
        
        return jobTaskCounts;
    }
}
