import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getAssignedJobs from '@salesforce/apex/ROSEJobService.getAssignedJobs';
import Id from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';

export default class RoseJobList extends NavigationMixin(LightningElement) {
    @track jobs = [];
    @track filteredJobs = [];
    @track selectedFilter = 'all';
    @track isLoading = false;
    @track error;
    
    userId = Id;
    wiredJobsResult;
    
    get filterOptions() {
        return [
            { label: 'All', value: 'all' },
            { label: 'New', value: 'New' },
            { label: 'In Progress', value: 'In Progress' }
        ];
    }
    
    get hasJobs() {
        return this.filteredJobs && this.filteredJobs.length > 0;
    }
    
    get emptyStateMessage() {
        return `No ${this.selectedFilter === 'all' ? '' : this.selectedFilter} jobs assigned.`;
    }
    
    @wire(getAssignedJobs, { fieldUserId: '$userId' })
    wiredJobs(result) {
        this.wiredJobsResult = result;
        const { data, error } = result;
        
        if (data) {
            // Calculate completion progress for each job
            this.jobs = data.map(job => {
                const tasks = job.Tasks__r || [];
                const completedTasks = tasks.filter(task => task.Status__c === 'Completed').length;
                const totalTasks = tasks.length;
                const progress = totalTasks > 0 ? Math.round((completedTasks / totalTasks) * 100) : 0;
                
                return {
                    ...job,
                    completedTasks,
                    totalTasks,
                    progress,
                    progressLabel: `${completedTasks}/${totalTasks} tasks completed`,
                    priorityClass: this.getPriorityClass(job.Priority__c),
                    statusClass: this.getStatusClass(job.Status__c),
                    dueDateFormatted: job.Due_Date__c ? new Date(job.Due_Date__c).toLocaleDateString() : 'No due date'
                };
            });
            
            this.applyFilter();
            this.error = undefined;
        } else if (error) {
            this.error = error.body ? error.body.message : error.message;
            this.jobs = [];
            this.filteredJobs = [];
        }
    }
    
    handleFilterChange(event) {
        this.selectedFilter = event.detail.value;
        this.applyFilter();
    }
    
    applyFilter() {
        if (this.selectedFilter === 'all') {
            this.filteredJobs = [...this.jobs];
        } else {
            this.filteredJobs = this.jobs.filter(job => job.Status__c === this.selectedFilter);
        }
    }
    
    handleJobClick(event) {
        const jobId = event.currentTarget.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__component',
            attributes: {
                componentName: 'c__roseTaskViewer'
            },
            state: {
                c__jobId: jobId
            }
        });
    }
    
    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredJobsResult)
            .then(() => {
                this.isLoading = false;
                this.dispatchEvent(
                    new CustomEvent('refresh', {
                        detail: { message: 'Jobs refreshed successfully' }
                    })
                );
            })
            .catch(error => {
                this.isLoading = false;
                this.error = error.body ? error.body.message : error.message;
            });
    }
    
    getPriorityClass(priority) {
        const classMap = {
            'High': 'priority-high',
            'Medium': 'priority-medium',
            'Low': 'priority-low'
        };
        return classMap[priority] || 'priority-medium';
    }
    
    getStatusClass(status) {
        const classMap = {
            'New': 'status-new',
            'In Progress': 'status-in-progress',
            'Completed': 'status-completed',
            'Synced': 'status-synced'
        };
        return classMap[status] || 'status-new';
    }
    
    connectedCallback() {
        // Listen for sync complete events
        window.addEventListener('syncComplete', this.handleSyncComplete.bind(this));
    }
    
    disconnectedCallback() {
        window.removeEventListener('syncComplete', this.handleSyncComplete.bind(this));
    }
    
    handleSyncComplete() {
        this.handleRefresh();
    }
}
