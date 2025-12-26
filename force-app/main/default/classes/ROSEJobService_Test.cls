/**
 * Test class for ROSEJobService
 */
@IsTest
private class ROSEJobService_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create field user
        ROSE_Field_User__c fieldUser = new ROSE_Field_User__c(
            Name = 'Test User',
            Status__c = 'Active',
            Region__c = 'West'
        );
        insert fieldUser;
        
        // Create jobs
        List<ROSE_Job__c> jobs = new List<ROSE_Job__c>{
            new ROSE_Job__c(
                Name = 'Job 1',
                Assigned_User__c = fieldUser.Id,
                Status__c = 'New',
                Priority__c = 'High',
                Due_Date__c = Date.today().addDays(7)
            ),
            new ROSE_Job__c(
                Name = 'Job 2',
                Assigned_User__c = fieldUser.Id,
                Status__c = 'In Progress',
                Priority__c = 'Medium',
                Due_Date__c = Date.today().addDays(14)
            )
        };
        insert jobs;
        
        // Create tasks for Job 1
        List<ROSE_Task__c> tasks = new List<ROSE_Task__c>{
            new ROSE_Task__c(
                ROSE_Job__c = jobs[0].Id,
                Name = 'Task 1',
                Task_Type__c = 'Collect Data',
                Sequence_Order__c = 1,
                Status__c = 'Pending'
            ),
            new ROSE_Task__c(
                ROSE_Job__c = jobs[0].Id,
                Name = 'Task 2',
                Task_Type__c = 'View Data',
                Sequence_Order__c = 2,
                Status__c = 'Pending'
            ),
            new ROSE_Task__c(
                ROSE_Job__c = jobs[1].Id,
                Name = 'Task 3',
                Task_Type__c = 'View Resource',
                Sequence_Order__c = 1,
                Status__c = 'Completed',
                Completed_Date__c = DateTime.now()
            )
        };
        insert tasks;
    }
    
    @IsTest
    static void testGetAssignedJobs() {
        ROSE_Field_User__c fieldUser = [SELECT Id FROM ROSE_Field_User__c LIMIT 1];
        
        Test.startTest();
        List<ROSE_Job__c> jobs = ROSEJobService.getAssignedJobs(fieldUser.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, jobs, 'Jobs should not be null');
        System.assertEquals(2, jobs.size(), 'Should have 2 jobs');
        System.assertEquals('Job 1', jobs[0].Name, 'First job should be Job 1 (High priority)');
        System.assertNotEquals(null, jobs[0].Tasks__r, 'Tasks should be included');
        System.assertEquals(2, jobs[0].Tasks__r.size(), 'Job 1 should have 2 tasks');
    }
    
    @IsTest
    static void testGetAssignedJobsNullId() {
        try {
            Test.startTest();
            ROSEJobService.getAssignedJobs(null);
            Test.stopTest();
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(true, 'Exception expected for null ID');
        }
    }
    
    @IsTest
    static void testGetTasksForJob() {
        ROSE_Job__c job = [SELECT Id FROM ROSE_Job__c WHERE Name = 'Job 1' LIMIT 1];
        
        Test.startTest();
        List<ROSE_Task__c> tasks = ROSEJobService.getTasksForJob(job.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, tasks, 'Tasks should not be null');
        System.assertEquals(2, tasks.size(), 'Should have 2 tasks');
        System.assertEquals(1, tasks[0].Sequence_Order__c, 'First task should have sequence 1');
        System.assertEquals(2, tasks[1].Sequence_Order__c, 'Second task should have sequence 2');
    }
    
    @IsTest
    static void testUpdateTaskStatus() {
        ROSE_Task__c task = [SELECT Id, Status__c FROM ROSE_Task__c WHERE Name = 'Task 1' LIMIT 1];
        
        Test.startTest();
        ROSEJobService.updateTaskStatus(task.Id, 'In Progress');
        Test.stopTest();
        
        ROSE_Task__c updatedTask = [SELECT Status__c, Completed_Date__c FROM ROSE_Task__c WHERE Id = :task.Id];
        System.assertEquals('In Progress', updatedTask.Status__c, 'Status should be updated');
        System.assertEquals(null, updatedTask.Completed_Date__c, 'Completed date should be null');
    }
    
    @IsTest
    static void testUpdateTaskStatusCompleted() {
        ROSE_Task__c task = [SELECT Id FROM ROSE_Task__c WHERE Name = 'Task 1' LIMIT 1];
        
        Test.startTest();
        ROSEJobService.updateTaskStatus(task.Id, 'Completed');
        Test.stopTest();
        
        ROSE_Task__c updatedTask = [SELECT Status__c, Completed_Date__c FROM ROSE_Task__c WHERE Id = :task.Id];
        System.assertEquals('Completed', updatedTask.Status__c, 'Status should be Completed');
        System.assertNotEquals(null, updatedTask.Completed_Date__c, 'Completed date should be set');
    }
    
    @IsTest
    static void testCompleteAllTasksInJob() {
        ROSE_Job__c job = [SELECT Id FROM ROSE_Job__c WHERE Name = 'Job 1' LIMIT 1];
        List<ROSE_Task__c> tasks = [SELECT Id FROM ROSE_Task__c WHERE ROSE_Job__c = :job.Id ORDER BY Sequence_Order__c];
        
        Test.startTest();
        // Complete all tasks
        for (ROSE_Task__c task : tasks) {
            ROSEJobService.updateTaskStatus(task.Id, 'Completed');
        }
        Test.stopTest();
        
        ROSE_Job__c updatedJob = [SELECT Status__c, Completed_Date__c FROM ROSE_Job__c WHERE Id = :job.Id];
        System.assertEquals('Completed', updatedJob.Status__c, 'Job should be completed');
        System.assertNotEquals(null, updatedJob.Completed_Date__c, 'Job completed date should be set');
    }
    
    @IsTest
    static void testCompleteJob() {
        ROSE_Job__c job = [SELECT Id FROM ROSE_Job__c WHERE Name = 'Job 1' LIMIT 1];
        
        Test.startTest();
        ROSEJobService.completeJob(job.Id);
        Test.stopTest();
        
        ROSE_Job__c updatedJob = [SELECT Status__c, Completed_Date__c FROM ROSE_Job__c WHERE Id = :job.Id];
        System.assertEquals('Completed', updatedJob.Status__c, 'Status should be Completed');
        System.assertNotEquals(null, updatedJob.Completed_Date__c, 'Completed date should be set');
    }
    
    @IsTest
    static void testJobStatusInProgress() {
        ROSE_Job__c job = [SELECT Id, Status__c FROM ROSE_Job__c WHERE Name = 'Job 1' LIMIT 1];
        ROSE_Task__c task = [SELECT Id FROM ROSE_Task__c WHERE ROSE_Job__c = :job.Id LIMIT 1];
        
        System.assertEquals('New', job.Status__c, 'Job should initially be New');
        
        Test.startTest();
        ROSEJobService.updateTaskStatus(task.Id, 'In Progress');
        Test.stopTest();
        
        ROSE_Job__c updatedJob = [SELECT Status__c FROM ROSE_Job__c WHERE Id = :job.Id];
        System.assertEquals('In Progress', updatedJob.Status__c, 'Job should be In Progress');
    }
    
    @IsTest
    static void testBulkJobOperations() {
        ROSE_Field_User__c fieldUser = [SELECT Id FROM ROSE_Field_User__c LIMIT 1];
        
        // Create 200 jobs with tasks
        List<ROSE_Job__c> jobs = new List<ROSE_Job__c>();
        for (Integer i = 0; i < 200; i++) {
            jobs.add(new ROSE_Job__c(
                Name = 'Bulk Job ' + i,
                Assigned_User__c = fieldUser.Id,
                Status__c = 'New',
                Priority__c = 'Medium'
            ));
        }
        insert jobs;
        
        List<ROSE_Task__c> tasks = new List<ROSE_Task__c>();
        for (ROSE_Job__c job : jobs) {
            tasks.add(new ROSE_Task__c(
                ROSE_Job__c = job.Id,
                Name = 'Task for ' + job.Name,
                Task_Type__c = 'Collect Data',
                Status__c = 'Pending'
            ));
        }
        insert tasks;
        
        Test.startTest();
        List<ROSE_Job__c> retrievedJobs = ROSEJobService.getAssignedJobs(fieldUser.Id);
        Test.stopTest();
        
        System.assertNotEquals(0, retrievedJobs.size(), 'Should retrieve jobs');
    }
}
