import { LightningElement, api, track } from 'lwc';
import getTasksForJob from '@salesforce/apex/RoseJobService.getTasksForJob';
import { getTasksByJobId } from 'c/roseUtils';

export default class RoseTaskViewer extends LightningElement {
    @api jobId;
    @track tasks = [];
    @track loading = true;

    connectedCallback() {
        this.loadTasks();
    }

    async loadTasks() {
        this.loading = true;
        try {
            const tasks = await getTasksForJob({ jobId: this.jobId });
            this.tasks = tasks.map(t => ({
                id: t.Id,
                name: t.Name,
                taskType: t.Task_Type__c,
                status: t.Status__c,
                sequenceOrder: t.Sequence_Order__c
            }));
        } catch (error) {
            this.tasks = await getTasksByJobId(this.jobId);
        } finally {
            this.loading = false;
        }
    }

    get hasTasks() {
        return this.tasks && this.tasks.length > 0;
    }

    handleTaskClick(event) {
        const taskId = event.currentTarget.dataset.taskId;
        // Navigate to appropriate component based on task type
    }
}
