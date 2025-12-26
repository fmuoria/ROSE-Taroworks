import { LightningElement, api, track } from 'lwc';
import { isOnline, syncWithServer, getUnsyncedResponses, getUnsyncedMedia, enableAutoSync } from 'c/roseUtils';

export default class RoseSyncStatus extends LightningElement {
    @api fieldUserId;
    @track online = navigator.onLine;
    @track syncing = false;
    @track lastSyncTime = null;
    @track pendingResponsesCount = 0;
    @track pendingMediaCount = 0;
    @track error = null;
    @track successMessage = null;
    @track syncProgressText = '';

    connectedCallback() {
        // Load last sync time from localStorage
        const storedTime = localStorage.getItem('lastSyncTime');
        if (storedTime) {
            this.lastSyncTime = new Date(storedTime);
        }

        // Listen for online/offline events
        window.addEventListener('online', this.handleOnlineStatus.bind(this));
        window.addEventListener('offline', this.handleOfflineStatus.bind(this));

        // Enable auto-sync
        enableAutoSync(this.fieldUserId);

        // Check pending items
        this.checkPendingItems();

        // Auto-sync on load if online
        if (this.online && !this.lastSyncTime) {
            this.handleSync();
        }
    }

    disconnectedCallback() {
        window.removeEventListener('online', this.handleOnlineStatus.bind(this));
        window.removeEventListener('offline', this.handleOfflineStatus.bind(this));
    }

    async checkPendingItems() {
        try {
            const responses = await getUnsyncedResponses();
            const media = await getUnsyncedMedia();
            
            this.pendingResponsesCount = responses ? responses.length : 0;
            this.pendingMediaCount = media ? media.length : 0;
        } catch (error) {
            console.error('Error checking pending items:', error);
        }
    }

    handleOnlineStatus() {
        this.online = true;
    }

    handleOfflineStatus() {
        this.online = false;
    }

    async handleSync() {
        if (!this.online) {
            this.error = 'Cannot sync while offline';
            setTimeout(() => {
                this.error = null;
            }, 3000);
            return;
        }

        this.syncing = true;
        this.error = null;
        this.successMessage = null;
        this.syncProgressText = 'Synchronizing...';

        try {
            const result = await syncWithServer(this.fieldUserId, this.lastSyncTime);
            
            this.lastSyncTime = new Date(result.syncTime);
            localStorage.setItem('lastSyncTime', result.syncTime);

            this.successMessage = `Sync successful! ↑${result.recordsUp} ↓${result.recordsDown}`;
            
            // Refresh pending items
            await this.checkPendingItems();

            // Clear success message after 5 seconds
            setTimeout(() => {
                this.successMessage = null;
            }, 5000);

            // Dispatch event for other components to refresh
            this.dispatchEvent(new CustomEvent('syncomplete', {
                detail: { result },
                bubbles: true,
                composed: true
            }));

        } catch (error) {
            this.error = 'Sync failed: ' + (error.body?.message || error.message);
            console.error('Sync error:', error);
        } finally {
            this.syncing = false;
            this.syncProgressText = '';
        }
    }

    get statusIcon() {
        return this.online ? 'utility:connected_apps' : 'utility:offline';
    }

    get statusText() {
        return this.online ? 'Online' : 'Offline';
    }

    get statusVariant() {
        return this.online ? 'success' : 'error';
    }

    get statusClass() {
        return this.online ? 'status-text online' : 'status-text offline';
    }

    get lastSyncDisplay() {
        if (!this.lastSyncTime) {
            return 'Never';
        }
        
        const now = new Date();
        const diff = now - this.lastSyncTime;
        const minutes = Math.floor(diff / 60000);
        
        if (minutes < 1) {
            return 'Just now';
        } else if (minutes < 60) {
            return `${minutes} minute${minutes > 1 ? 's' : ''} ago`;
        } else {
            const hours = Math.floor(minutes / 60);
            return `${hours} hour${hours > 1 ? 's' : ''} ago`;
        }
    }

    get hasPendingItems() {
        return this.pendingResponsesCount > 0 || this.pendingMediaCount > 0;
    }

    get pendingItemsText() {
        const items = [];
        if (this.pendingResponsesCount > 0) {
            items.push(`${this.pendingResponsesCount} form${this.pendingResponsesCount > 1 ? 's' : ''}`);
        }
        if (this.pendingMediaCount > 0) {
            items.push(`${this.pendingMediaCount} media file${this.pendingMediaCount > 1 ? 's' : ''}`);
        }
        return `Pending upload: ${items.join(', ')}`;
    }

    get syncDisabled() {
        return !this.online || this.syncing;
    }
}
