import { LightningElement, track } from 'lwc';
import performSync from '@salesforce/apex/ROSESyncService.performSync';
import Id from '@salesforce/user/Id';

export default class RoseSyncStatus extends LightningElement {
    @track isOnline = navigator.onLine;
    @track isSyncing = false;
    @track lastSyncTime;
    @track pendingCount = 0;
    @track syncError;
    @track syncSuccess = false;
    
    userId = Id;
    
    get onlineStatusIcon() {
        return this.isOnline ? 'utility:wifi' : 'utility:offline';
    }
    
    get onlineStatusClass() {
        return this.isOnline ? 'status-online' : 'status-offline';
    }
    
    get onlineStatusText() {
        return this.isOnline ? 'Online' : 'Offline';
    }
    
    get lastSyncFormatted() {
        if (!this.lastSyncTime) {
            return 'Never';
        }
        
        const now = new Date();
        const syncTime = new Date(this.lastSyncTime);
        const diffMs = now - syncTime;
        const diffMins = Math.floor(diffMs / 60000);
        
        if (diffMins < 1) return 'Just now';
        if (diffMins < 60) return `${diffMins} min ago`;
        
        const diffHours = Math.floor(diffMins / 60);
        if (diffHours < 24) return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
        
        const diffDays = Math.floor(diffHours / 24);
        return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`;
    }
    
    get showSyncButton() {
        return this.isOnline && !this.isSyncing;
    }
    
    connectedCallback() {
        // Load last sync time from localStorage
        this.loadLastSyncTime();
        
        // Load pending count from IndexedDB (simulated with localStorage for now)
        this.loadPendingCount();
        
        // Add online/offline event listeners
        window.addEventListener('online', this.handleOnlineStatus.bind(this));
        window.addEventListener('offline', this.handleOfflineStatus.bind(this));
        
        // Auto-sync when coming online
        if (this.isOnline && this.pendingCount > 0) {
            this.handleAutoSync();
        }
    }
    
    disconnectedCallback() {
        window.removeEventListener('online', this.handleOnlineStatus.bind(this));
        window.removeEventListener('offline', this.handleOfflineStatus.bind(this));
    }
    
    handleOnlineStatus() {
        this.isOnline = true;
        this.handleAutoSync();
    }
    
    handleOfflineStatus() {
        this.isOnline = false;
    }
    
    async handleManualSync() {
        if (!this.isOnline) {
            this.syncError = 'Cannot sync while offline';
            return;
        }
        
        await this.performSyncOperation();
    }
    
    async handleAutoSync() {
        if (this.pendingCount > 0) {
            await this.performSyncOperation();
        }
    }
    
    async performSyncOperation() {
        this.isSyncing = true;
        this.syncError = null;
        this.syncSuccess = false;
        
        try {
            // Build sync request
            const syncRequest = {
                lastMetadataSync: this.getLastMetadataSync(),
                lastAssignmentSync: this.getLastAssignmentSync(),
                formResponses: await this.getPendingFormResponses(),
                mediaFiles: await this.getPendingMediaFiles()
            };
            
            // Perform sync
            const result = await performSync({
                userId: this.userId,
                syncRequestJSON: JSON.stringify(syncRequest)
            });
            
            if (result.success) {
                this.lastSyncTime = result.timestamp;
                this.saveLastSyncTime();
                this.syncSuccess = true;
                this.pendingCount = 0;
                
                // Dispatch sync complete event
                window.dispatchEvent(new CustomEvent('syncComplete', {
                    detail: { result }
                }));
                
                // Clear success message after 3 seconds
                setTimeout(() => {
                    this.syncSuccess = false;
                }, 3000);
            } else {
                this.syncError = result.errorMessage || 'Sync failed';
            }
        } catch (error) {
            this.syncError = error.body ? error.body.message : error.message;
        } finally {
            this.isSyncing = false;
        }
    }
    
    loadLastSyncTime() {
        const stored = localStorage.getItem('rose_last_sync');
        if (stored) {
            this.lastSyncTime = stored;
        }
    }
    
    saveLastSyncTime() {
        localStorage.setItem('rose_last_sync', this.lastSyncTime);
    }
    
    loadPendingCount() {
        const stored = localStorage.getItem('rose_pending_count');
        this.pendingCount = stored ? parseInt(stored, 10) : 0;
    }
    
    getLastMetadataSync() {
        const stored = localStorage.getItem('rose_last_metadata_sync');
        return stored || null;
    }
    
    getLastAssignmentSync() {
        const stored = localStorage.getItem('rose_last_assignment_sync');
        return stored || null;
    }
    
    async getPendingFormResponses() {
        // In production, this would read from IndexedDB
        // For now, return empty array
        return [];
    }
    
    async getPendingMediaFiles() {
        // In production, this would read from IndexedDB
        // For now, return empty array
        return [];
    }
}
