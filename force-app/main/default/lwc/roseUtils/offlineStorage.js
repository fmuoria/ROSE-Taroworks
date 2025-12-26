/**
 * Offline Storage Module using IndexedDB
 * Provides CRUD operations for offline data storage
 */

const DB_NAME = 'roseFieldApp';
const DB_VERSION = 1;

// Object store names
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
 * Initialize IndexedDB
 */
function initDB() {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(DB_NAME, DB_VERSION);

        request.onerror = () => reject(request.error);
        request.onsuccess = () => resolve(request.result);

        request.onupgradeneeded = (event) => {
            const db = event.target.result;

            // Create object stores if they don't exist
            if (!db.objectStoreNames.contains(STORES.JOBS)) {
                const jobStore = db.createObjectStore(STORES.JOBS, { keyPath: 'id' });
                jobStore.createIndex('status', 'status', { unique: false });
                jobStore.createIndex('synced', 'synced', { unique: false });
            }

            if (!db.objectStoreNames.contains(STORES.TASKS)) {
                const taskStore = db.createObjectStore(STORES.TASKS, { keyPath: 'id' });
                taskStore.createIndex('jobId', 'jobId', { unique: false });
                taskStore.createIndex('status', 'status', { unique: false });
            }

            if (!db.objectStoreNames.contains(STORES.FORM_DEFINITIONS)) {
                db.createObjectStore(STORES.FORM_DEFINITIONS, { keyPath: 'id' });
            }

            if (!db.objectStoreNames.contains(STORES.FORM_FIELDS)) {
                const fieldStore = db.createObjectStore(STORES.FORM_FIELDS, { keyPath: 'id' });
                fieldStore.createIndex('formDefinitionId', 'formDefinitionId', { unique: false });
            }

            if (!db.objectStoreNames.contains(STORES.FORM_RESPONSES)) {
                const responseStore = db.createObjectStore(STORES.FORM_RESPONSES, { keyPath: 'id' });
                responseStore.createIndex('synced', 'synced', { unique: false });
                responseStore.createIndex('taskId', 'taskId', { unique: false });
            }

            if (!db.objectStoreNames.contains(STORES.MEDIA_FILES)) {
                const mediaStore = db.createObjectStore(STORES.MEDIA_FILES, { keyPath: 'id' });
                mediaStore.createIndex('formResponseId', 'formResponseId', { unique: false });
                mediaStore.createIndex('synced', 'synced', { unique: false });
            }

            if (!db.objectStoreNames.contains(STORES.SYNC_QUEUE)) {
                const syncStore = db.createObjectStore(STORES.SYNC_QUEUE, { keyPath: 'id', autoIncrement: true });
                syncStore.createIndex('type', 'type', { unique: false });
            }
        };
    });
}

/**
 * Save data to object store
 */
async function saveData(storeName, data) {
    const db = await initDB();
    return new Promise((resolve, reject) => {
        const transaction = db.transaction([storeName], 'readwrite');
        const store = transaction.objectStore(storeName);

        const request = Array.isArray(data)
            ? data.map(item => store.put(item))
            : store.put(data);

        transaction.oncomplete = () => resolve();
        transaction.onerror = () => reject(transaction.error);
    });
}

/**
 * Get data from object store
 */
async function getData(storeName, key) {
    const db = await initDB();
    return new Promise((resolve, reject) => {
        const transaction = db.transaction([storeName], 'readonly');
        const store = transaction.objectStore(storeName);
        const request = key ? store.get(key) : store.getAll();

        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
    });
}

/**
 * Delete data from object store
 */
async function deleteData(storeName, key) {
    const db = await initDB();
    return new Promise((resolve, reject) => {
        const transaction = db.transaction([storeName], 'readwrite');
        const store = transaction.objectStore(storeName);
        const request = store.delete(key);

        transaction.oncomplete = () => resolve();
        transaction.onerror = () => reject(transaction.error);
    });
}

/**
 * Get data by index
 */
async function getDataByIndex(storeName, indexName, value) {
    const db = await initDB();
    return new Promise((resolve, reject) => {
        const transaction = db.transaction([storeName], 'readonly');
        const store = transaction.objectStore(storeName);
        const index = store.index(indexName);
        const request = index.getAll(value);

        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
    });
}

// Exported functions for specific stores
export const saveJobs = (jobs) => saveData(STORES.JOBS, jobs);
export const getOfflineJobs = () => getData(STORES.JOBS);
export const getJobById = (id) => getData(STORES.JOBS, id);

export const saveTasks = (tasks) => saveData(STORES.TASKS, tasks);
export const getTasksByJobId = (jobId) => getDataByIndex(STORES.TASKS, 'jobId', jobId);

export const saveFormDefinitions = (forms) => saveData(STORES.FORM_DEFINITIONS, forms);
export const getFormDefinitions = () => getData(STORES.FORM_DEFINITIONS);

export const saveFormFields = (fields) => saveData(STORES.FORM_FIELDS, fields);
export const getFormFieldsByDefinition = (formId) => 
    getDataByIndex(STORES.FORM_FIELDS, 'formDefinitionId', formId);

export const saveFormResponse = (response) => saveData(STORES.FORM_RESPONSES, response);
export const getUnsyncedResponses = () => getDataByIndex(STORES.FORM_RESPONSES, 'synced', false);

export const saveMediaFile = (media) => saveData(STORES.MEDIA_FILES, media);
export const getUnsyncedMedia = () => getDataByIndex(STORES.MEDIA_FILES, 'synced', false);

export const addToSyncQueue = (item) => saveData(STORES.SYNC_QUEUE, item);
export const getSyncQueue = () => getData(STORES.SYNC_QUEUE);
export const clearSyncQueue = async () => {
    const db = await initDB();
    return new Promise((resolve, reject) => {
        const transaction = db.transaction([STORES.SYNC_QUEUE], 'readwrite');
        const store = transaction.objectStore(STORES.SYNC_QUEUE);
        const request = store.clear();

        transaction.oncomplete = () => resolve();
        transaction.onerror = () => reject(transaction.error);
    });
};
