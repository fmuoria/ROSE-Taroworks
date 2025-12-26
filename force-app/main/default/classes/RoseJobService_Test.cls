/**
 * @description Test class for RoseJobService
 * @author ROSE Team
 * @date 2025
 */
@isTest
private class RoseJobService_Test {
    
    @testSetup
    static void setup() {
        // Create test data
        Field_User__c fieldUser = new Field_User__c(
            Name = 'Test Field User',
            Status__c = 'Active',
            Region__c = 'North'
        );
        insert fieldUser;
        
        Job__c job1 = new Job__c(
            Name = 'Job 1',
            Assigned_User__c = fieldUser.Id,
            Status__c = 'New',
            Priority__c = 'High',
            Due_Date__c = Date.today().addDays(7)
        );
        
        Job__c job2 = new Job__c(
            Name = 'Job 2',
            Assigned_User__c = fieldUser.Id,
            Status__c = 'In Progress',
            Priority__c = 'Medium',
            Due_Date__c = Date.today().addDays(14)
        );
        
        insert new List<Job__c>{ job1, job2 };
        
        Task__c task1 = new Task__c(
            Name = 'Task 1',
            Job__c = job1.Id,
            Task_Type__c = 'Collect Data',
            Sequence_Order__c = 1,
            Status__c = 'Pending'
        );
        
        Task__c task2 = new Task__c(
            Name = 'Task 2',
            Job__c = job1.Id,
            Task_Type__c = 'View Data',
            Sequence_Order__c = 2,
            Status__c = 'Pending'
        );
        
        Task__c task3 = new Task__c(
            Name = 'Task 3',
            Job__c = job2.Id,
            Task_Type__c = 'Collect Data',
            Sequence_Order__c = 1,
            Status__c = 'Pending'
        );
        
        insert new List<Task__c>{ task1, task2, task3 };
    }
    
    @isTest
    static void testGetAssignedJobs() {
        Field_User__c fieldUser = [SELECT Id FROM Field_User__c LIMIT 1];
        
        Test.startTest();
        List<Job__c> jobs = RoseJobService.getAssignedJobs(fieldUser.Id);
        Test.stopTest();
        
        System.assertEquals(2, jobs.size(), 'Should return 2 jobs');
        System.assertEquals('High', jobs[0].Priority__c, 'First job should be high priority');
    }
    
    @isTest
    static void testGetAssignedJobsNullId() {
        Test.startTest();
        try {
            RoseJobService.getAssignedJobs(null);
            System.assert(false, 'Should throw exception');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Exception expected');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetTasksForJob() {
        Job__c job = [SELECT Id FROM Job__c WHERE Name = 'Job 1' LIMIT 1];
        
        Test.startTest();
        List<Task__c> tasks = RoseJobService.getTasksForJob(job.Id);
        Test.stopTest();
        
        System.assertEquals(2, tasks.size(), 'Should return 2 tasks');
        System.assertEquals(1, tasks[0].Sequence_Order__c, 'Tasks should be ordered by sequence');
    }
    
    @isTest
    static void testGetTasksForJobNullId() {
        Test.startTest();
        try {
            RoseJobService.getTasksForJob(null);
            System.assert(false, 'Should throw exception');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Exception expected');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateTaskStatus() {
        Task__c task = [SELECT Id FROM Task__c WHERE Name = 'Task 1' LIMIT 1];
        
        Test.startTest();
        RoseJobService.updateTaskStatus(task.Id, 'In Progress');
        Test.stopTest();
        
        Task__c updatedTask = [SELECT Status__c FROM Task__c WHERE Id = :task.Id];
        System.assertEquals('In Progress', updatedTask.Status__c, 'Status should be updated');
    }
    
    @isTest
    static void testUpdateTaskStatusCompleted() {
        Task__c task = [SELECT Id FROM Task__c WHERE Name = 'Task 1' LIMIT 1];
        
        Test.startTest();
        RoseJobService.updateTaskStatus(task.Id, 'Completed');
        Test.stopTest();
        
        Task__c updatedTask = [SELECT Status__c, Completed_Date__c FROM Task__c WHERE Id = :task.Id];
        System.assertEquals('Completed', updatedTask.Status__c, 'Status should be completed');
        System.assertNotEquals(null, updatedTask.Completed_Date__c, 'Completed date should be set');
    }
    
    @isTest
    static void testCompleteJob() {
        Job__c job = [SELECT Id FROM Job__c WHERE Name = 'Job 1' LIMIT 1];
        
        Test.startTest();
        RoseJobService.completeJob(job.Id);
        Test.stopTest();
        
        Job__c updatedJob = [SELECT Status__c, Completed_Date__c FROM Job__c WHERE Id = :job.Id];
        System.assertEquals('Completed', updatedJob.Status__c, 'Job status should be completed');
        System.assertNotEquals(null, updatedJob.Completed_Date__c, 'Completed date should be set');
    }
    
    @isTest
    static void testCompleteJobNullId() {
        Test.startTest();
        try {
            RoseJobService.completeJob(null);
            System.assert(false, 'Should throw exception');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Exception expected');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testJobAutoCompleteWhenAllTasksCompleted() {
        Job__c job = [SELECT Id FROM Job__c WHERE Name = 'Job 1' LIMIT 1];
        List<Task__c> tasks = [SELECT Id FROM Task__c WHERE Job__c = :job.Id];
        
        Test.startTest();
        // Complete all tasks
        for (Task__c task : tasks) {
            RoseJobService.updateTaskStatus(task.Id, 'Completed');
        }
        Test.stopTest();
        
        Job__c updatedJob = [SELECT Status__c FROM Job__c WHERE Id = :job.Id];
        System.assertEquals('Completed', updatedJob.Status__c, 'Job should auto-complete');
    }
    
    @isTest
    static void testGetJobTaskCounts() {
        Field_User__c fieldUser = [SELECT Id FROM Field_User__c LIMIT 1];
        
        Test.startTest();
        Map<Id, Integer> taskCounts = RoseJobService.getJobTaskCounts(fieldUser.Id);
        Test.stopTest();
        
        System.assertEquals(2, taskCounts.size(), 'Should have counts for 2 jobs');
    }
}
