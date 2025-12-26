/**
 * Offline storage utilities using IndexedDB
 * Database: roseFieldApp
 */

const DB_NAME = 'roseFieldApp';
const DB_VERSION = 1;

// Store names
const STORES = {
    JOBS: 'jobs',
    TASKS: 'tasks',
    FORM_DEFINITIONS: 'formDefinitions',
    FORM_FIELDS: 'formFields',
    FORM_RESPONSES: 'formResponses',
    MEDIA_FILES: 'mediaFiles',
    SYNC_QUEUE: 'syncQueue'
};

/**
 * Open IndexedDB database
 * @returns {Promise<IDBDatabase>}
 */
export async function openDB() {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(DB_NAME, DB_VERSION);
        
        request.onerror = () => reject(request.error);
        request.onsuccess = () => resolve(request.result);
        
        request.onupgradeneeded = (event) => {
            const db = event.target.result;
            
            // Create jobs store
            if (!db.objectStoreNames.contains(STORES.JOBS)) {
                const jobsStore = db.createObjectStore(STORES.JOBS, { keyPath: 'Id' });
                jobsStore.createIndex('Status__c', 'Status__c', { unique: false });
                jobsStore.createIndex('Assigned_User__c', 'Assigned_User__c', { unique: false });
            }
            
            // Create tasks store
            if (!db.objectStoreNames.contains(STORES.TASKS)) {
                const tasksStore = db.createObjectStore(STORES.TASKS, { keyPath: 'Id' });
                tasksStore.createIndex('ROSE_Job__c', 'ROSE_Job__c', { unique: false });
                tasksStore.createIndex('Status__c', 'Status__c', { unique: false });
            }
            
            // Create form definitions store
            if (!db.objectStoreNames.contains(STORES.FORM_DEFINITIONS)) {
                const formDefStore = db.createObjectStore(STORES.FORM_DEFINITIONS, { keyPath: 'Id' });
                formDefStore.createIndex('Active__c', 'Active__c', { unique: false });
            }
            
            // Create form fields store
            if (!db.objectStoreNames.contains(STORES.FORM_FIELDS)) {
                const formFieldsStore = db.createObjectStore(STORES.FORM_FIELDS, { keyPath: 'Id' });
                formFieldsStore.createIndex('ROSE_Form_Definition__c', 'ROSE_Form_Definition__c', { unique: false });
                formFieldsStore.createIndex('Display_Order__c', 'Display_Order__c', { unique: false });
            }
            
            // Create form responses store
            if (!db.objectStoreNames.contains(STORES.FORM_RESPONSES)) {
                const formResponsesStore = db.createObjectStore(STORES.FORM_RESPONSES, { 
                    keyPath: 'localId', 
                    autoIncrement: true 
                });
                formResponsesStore.createIndex('Synced__c', 'Synced__c', { unique: false });
                formResponsesStore.createIndex('ROSE_Task__c', 'ROSE_Task__c', { unique: false });
            }
            
            // Create media files store
            if (!db.objectStoreNames.contains(STORES.MEDIA_FILES)) {
                const mediaFilesStore = db.createObjectStore(STORES.MEDIA_FILES, { 
                    keyPath: 'localId', 
                    autoIncrement: true 
                });
                mediaFilesStore.createIndex('Synced__c', 'Synced__c', { unique: false });
                mediaFilesStore.createIndex('formResponseId', 'formResponseId', { unique: false });
            }
            
            // Create sync queue store
            if (!db.objectStoreNames.contains(STORES.SYNC_QUEUE)) {
                db.createObjectStore(STORES.SYNC_QUEUE, { keyPath: 'timestamp' });
            }
        };
    });
}

/**
 * Save job to IndexedDB
 * @param {Object} job Job record
 * @returns {Promise<void>}
 */
export async function saveJob(job) {
    const db = await openDB();
    return new Promise((resolve, reject) => {
        const transaction = db.transaction([STORES.JOBS], 'readwrite');
        const store = transaction.objectStore(STORES.JOBS);
        const request = store.put(job);
        
        request.onsuccess = () => resolve();
        request.onerror = () => reject(request.error);
    });
}

/**
 * Load jobs from IndexedDB
 * @param {Object} filter Filter criteria
 * @returns {Promise<Array>}
 */
export async function loadJobs(filter = {}) {
    const db = await openDB();
    return new Promise((resolve, reject) => {
        const transaction = db.transaction([STORES.JOBS], 'readonly');
        const store = transaction.objectStore(STORES.JOBS);
        const request = store.getAll();
        
        request.onsuccess = () => {
            let jobs = request.result;
            
            // Apply filters
            if (filter.status) {
                jobs = jobs.filter(job => job.Status__c === filter.status);
            }
            
            resolve(jobs);
        };
        request.onerror = () => reject(request.error);
    });
}

/**
 * Save form response to IndexedDB
 * @param {Object} response Form response object
 * @returns {Promise<number>} Local ID of saved response
 */
export async function saveFormResponse(response) {
    const db = await openDB();
    return new Promise((resolve, reject) => {
        const transaction = db.transaction([STORES.FORM_RESPONSES], 'readwrite');
        const store = transaction.objectStore(STORES.FORM_RESPONSES);
        
        // Add timestamp and default synced status
        response.createdAt = new Date().toISOString();
        response.Synced__c = response.Synced__c || false;
        
        const request = store.add(response);
        
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
    });
}

/**
 * Get pending form responses
 * @returns {Promise<Array>}
 */
export async function getPendingFormResponses() {
    const db = await openDB();
    return new Promise((resolve, reject) => {
        const transaction = db.transaction([STORES.FORM_RESPONSES], 'readonly');
        const store = transaction.objectStore(STORES.FORM_RESPONSES);
        const index = store.index('Synced__c');
        const request = index.getAll(false);
        
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
    });
}

/**
 * Mark form response as synced
 * @param {number} responseId Local ID of response
 * @returns {Promise<void>}
 */
export async function markAsSynced(responseId) {
    const db = await openDB();
    return new Promise((resolve, reject) => {
        const transaction = db.transaction([STORES.FORM_RESPONSES], 'readwrite');
        const store = transaction.objectStore(STORES.FORM_RESPONSES);
        const getRequest = store.get(responseId);
        
        getRequest.onsuccess = () => {
            const response = getRequest.result;
            if (response) {
                response.Synced__c = true;
                response.syncedAt = new Date().toISOString();
                const putRequest = store.put(response);
                putRequest.onsuccess = () => resolve();
                putRequest.onerror = () => reject(putRequest.error);
            } else {
                resolve();
            }
        };
        getRequest.onerror = () => reject(getRequest.error);
    });
}

/**
 * Cleanup synced jobs from IndexedDB
 * @returns {Promise<void>}
 */
export async function cleanupSyncedJobs() {
    const db = await openDB();
    return new Promise((resolve, reject) => {
        const transaction = db.transaction([STORES.JOBS], 'readwrite');
        const store = transaction.objectStore(STORES.JOBS);
        const index = store.index('Status__c');
        const request = index.openCursor('Synced');
        
        request.onsuccess = (event) => {
            const cursor = event.target.result;
            if (cursor) {
                cursor.delete();
                cursor.continue();
            } else {
                resolve();
            }
        };
        request.onerror = () => reject(request.error);
    });
}
