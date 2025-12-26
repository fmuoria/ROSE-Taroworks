/**
 * Sync Engine Module
 * Handles synchronization between device and Salesforce
 */

import performSync from '@salesforce/apex/RoseSyncService.performSync';
import { getUnsyncedResponses, getUnsyncedMedia, saveJobs, saveTasks, 
         saveFormDefinitions, saveFormFields, clearSyncQueue } from './offlineStorage';

/**
 * Check if device is online
 */
export function isOnline() {
    return navigator.onLine;
}

/**
 * Perform full sync with server
 */
export async function syncWithServer(fieldUserId, lastSyncTime) {
    if (!isOnline()) {
        throw new Error('Device is offline. Cannot sync.');
    }

    try {
        // Prepare sync request
        const pendingResponses = await getUnsyncedResponses();
        const pendingMedia = await getUnsyncedMedia();

        const syncRequest = {
            userId: fieldUserId,
            lastSyncTime: lastSyncTime,
            pendingResponses: pendingResponses.map(r => ({
                id: r.id,
                taskId: r.taskId,
                formDefinitionId: r.formDefinitionId,
                responseData: r.responseData,
                targetRecordId: r.targetRecordId,
                gpsLatitude: r.gpsLatitude,
                gpsLongitude: r.gpsLongitude,
                submittedDate: r.submittedDate,
                lastModifiedDate: r.lastModifiedDate
            })),
            pendingMedia: pendingMedia.map(m => ({
                id: m.id,
                formResponseId: m.formResponseId,
                fieldName: m.fieldName,
                fileName: m.fileName,
                fileData: m.fileData,
                gpsLatitude: m.gpsLatitude,
                gpsLongitude: m.gpsLongitude,
                capturedDate: m.capturedDate
            }))
        };

        // Call Apex sync service
        const result = await performSync({
            userId: fieldUserId,
            request: syncRequest
        });

        if (result.success) {
            // Store downloaded data
            if (result.metadata) {
                await saveFormDefinitions(result.metadata.formDefinitions);
                
                // Save form fields
                for (const [formId, fields] of Object.entries(result.metadata.formFields)) {
                    await saveFormFields(fields);
                }
            }

            if (result.assignments) {
                await saveJobs(result.assignments.jobs);
                
                // Save tasks
                for (const [jobId, tasks] of Object.entries(result.assignments.tasks)) {
                    await saveTasks(tasks);
                }
            }

            // Clear sync queue if all uploads successful
            const allSuccess = result.uploadStatuses.every(s => s.success);
            if (allSuccess) {
                await clearSyncQueue();
            }

            return {
                success: true,
                message: result.message,
                recordsUp: result.recordsUp,
                recordsDown: result.recordsDown,
                syncTime: result.syncTime
            };
        } else {
            throw new Error(result.message);
        }
    } catch (error) {
        console.error('Sync error:', error);
        throw error;
    }
}

/**
 * Schedule background sync
 */
export function scheduleBackgroundSync() {
    if ('serviceWorker' in navigator && 'SyncManager' in window) {
        navigator.serviceWorker.ready.then(function(registration) {
            return registration.sync.register('rose-sync');
        });
    }
}

/**
 * Auto-sync when online
 */
export function enableAutoSync(fieldUserId) {
    window.addEventListener('online', async () => {
        console.log('Device is online, starting auto-sync...');
        try {
            const lastSyncTime = localStorage.getItem('lastSyncTime');
            await syncWithServer(fieldUserId, lastSyncTime);
            localStorage.setItem('lastSyncTime', new Date().toISOString());
        } catch (error) {
            console.error('Auto-sync failed:', error);
        }
    });
}
