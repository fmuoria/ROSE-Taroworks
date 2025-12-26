import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getAssignedJobs from '@salesforce/apex/RoseJobService.getAssignedJobs';
import getJobTaskCounts from '@salesforce/apex/RoseJobService.getJobTaskCounts';
import { getOfflineJobs, saveJobs } from 'c/roseUtils';

export default class RoseJobList extends NavigationMixin(LightningElement) {
    @api fieldUserId;
    @track jobs = [];
    @track loading = true;
    @track filter = 'All';

    connectedCallback() {
        this.loadJobs();
    }

    async loadJobs() {
        this.loading = true;
        try {
            // Try to load from Salesforce first
            const jobs = await getAssignedJobs({ fieldUserId: this.fieldUserId });
            const taskCounts = await getJobTaskCounts({ fieldUserId: this.fieldUserId });
            
            this.jobs = jobs.map(job => this.transformJob(job, taskCounts));
            
            // Save to offline storage
            await saveJobs(this.jobs);
        } catch (error) {
            // If online fetch fails, load from offline storage
            console.error('Error loading jobs from server, loading offline:', error);
            this.jobs = await getOfflineJobs();
        } finally {
            this.loading = false;
        }
    }

    transformJob(job, taskCounts) {
        const totalTasks = taskCounts[job.Id] || 0;
        const completedTasks = 0; // Would need another query for this
        
        return {
            id: job.Id,
            name: job.Name,
            status: job.Status__c,
            dueDate: this.formatDate(job.Due_Date__c),
            priority: job.Priority__c,
            region: job.Region__c || 'N/A',
            description: job.Description__c,
            totalTasks: totalTasks,
            completedTasks: completedTasks,
            progressPercent: totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0,
            priorityClass: this.getPriorityClass(job.Priority__c)
        };
    }

    formatDate(dateString) {
        if (!dateString) return 'N/A';
        const date = new Date(dateString);
        return date.toLocaleDateString();
    }

    getPriorityClass(priority) {
        switch (priority) {
            case 'High':
                return 'slds-badge slds-theme_error';
            case 'Medium':
                return 'slds-badge slds-theme_warning';
            case 'Low':
                return 'slds-badge slds-theme_success';
            default:
                return 'slds-badge';
        }
    }

    get filteredJobs() {
        if (this.filter === 'All') {
            return this.jobs;
        }
        return this.jobs.filter(job => job.status === this.filter);
    }

    get hasJobs() {
        return this.filteredJobs && this.filteredJobs.length > 0;
    }

    get allVariant() {
        return this.filter === 'All' ? 'brand' : 'neutral';
    }

    get newVariant() {
        return this.filter === 'New' ? 'brand' : 'neutral';
    }

    get inProgressVariant() {
        return this.filter === 'In Progress' ? 'brand' : 'neutral';
    }

    handleFilterAll() {
        this.filter = 'All';
    }

    handleFilterNew() {
        this.filter = 'New';
    }

    handleFilterInProgress() {
        this.filter = 'In Progress';
    }

    handleJobClick(event) {
        const jobId = event.currentTarget.dataset.jobId;
        
        // Navigate to task viewer
        const config = {
            type: 'standard__component',
            attributes: {
                componentName: 'c__roseTaskViewer'
            },
            state: {
                c__jobId: jobId
            }
        };
        
        this[NavigationMixin.Navigate](config);
    }

    @api
    async refresh() {
        await this.loadJobs();
    }
}
