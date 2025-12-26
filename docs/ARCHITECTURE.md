# ROSE TaroWorks Architecture

## System Overview

ROSE TaroWorks is a 3-tier architecture:

1. **Mobile Client** - LWC components with IndexedDB for offline storage
2. **Salesforce Platform** - Apex services for business logic and data persistence
3. **Data Layer** - Custom objects with proper relationships

## Component Architecture

```
┌─────────────────────────────────────────┐
│         Mobile Device (Client)          │
├─────────────────────────────────────────┤
│  LWC Components                         │
│  ├── roseJobList                        │
│  ├── roseTaskViewer                     │
│  ├── roseDynamicForm                    │
│  ├── roseMediaCapture                   │
│  └── roseSyncStatus                     │
├─────────────────────────────────────────┤
│  IndexedDB (Offline Storage)            │
│  ├── jobs, tasks                        │
│  ├── formDefinitions, formFields        │
│  ├── formResponses (pending sync)       │
│  └── mediaFiles (base64 data)           │
└─────────────────────────────────────────┘
                  ↕ (Sync via REST/Apex)
┌─────────────────────────────────────────┐
│      Salesforce Platform (Server)       │
├─────────────────────────────────────────┤
│  Apex Services                          │
│  ├── ROSESyncService (orchestrator)    │
│  ├── ROSEFormService (form processing) │
│  ├── ROSEJobService (job management)   │
│  └── ROSEMediaService (media uploads)  │
├─────────────────────────────────────────┤
│  Custom Objects (Data Model)            │
│  ├── ROSE_Field_User__c                │
│  ├── ROSE_Job__c                        │
│  │   └── ROSE_Task__c (M-D)            │
│  │       └── ROSE_Form_Response__c     │
│  ├── ROSE_Form_Definition__c           │
│  │   └── ROSE_Form_Field__c (M-D)      │
│  ├── ROSE_Media_Attachment__c          │
│  ├── ROSE_Sync_Log__c                  │
│  └── ROSE_Conflict_Queue__c            │
└─────────────────────────────────────────┘
```

## Data Model ERD

```
ROSE_Field_User__c
    ↓ (Lookup)
ROSE_Job__c
    ↓ (Master-Detail)
ROSE_Task__c
    ↓ (Master-Detail)
ROSE_Form_Response__c
    ↓ (Lookup)
ROSE_Media_Attachment__c

ROSE_Form_Definition__c
    ↓ (Master-Detail)
ROSE_Form_Field__c
```

## Sync Flow (6 Phases)

### Phase 1: Authentication
- Validate OAuth token
- Refresh if needed
- Fail fast if no auth

### Phase 2: Metadata Sync (Download)
```javascript
GET /services/apexrest/ROSESyncService/metadata?lastSync=TIMESTAMP
Response: {
  formDefinitions: [...],
  formFields: [...]
}
```

### Phase 3: Assignment Sync (Download)
```javascript
GET /services/apexrest/ROSESyncService/assignments?userId=XXX&lastSync=TIMESTAMP
Response: {
  jobs: [...],
  tasks: [...],
  targetRecords: {...}
}
```

### Phase 4: Data Upload
```javascript
POST /services/apexrest/ROSESyncService/upload
Body: {
  formResponses: [...],
  mediaFiles: [...]
}
Response: {
  success: true,
  uploadStatus: { successCount: 10, failureCount: 0 }
}
```

### Phase 5: Conflict Resolution
- Compare server LastModifiedDate vs device timestamp
- Create ROSE_Conflict_Queue__c for conflicts
- Auto-resolve: last write wins (configurable)

### Phase 6: Cleanup
- Mark completed jobs as 'Synced'
- Remove synced data from IndexedDB
- Log sync event

## Security Model

### Object-Level Security (OLS)
- ROSE_Field_Worker profile has specific CRUD on each object
- Read-only on metadata (forms)
- Create on form responses and media
- Edit on jobs/tasks

### Record-Level Security (Sharing)
- Criteria-based sharing: Jobs shared with assigned field user
- Master-Detail: Tasks inherit from Jobs
- Private OWD with sharing rules

### Field-Level Security (FLS)
- Hide sensitive financial fields from field workers
- Ensure proper access to data collection fields

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Lightning Web Components (LWC) |
| Offline Storage | IndexedDB API |
| Backend | Apex (Salesforce) |
| Database | Salesforce Custom Objects |
| Security | Salesforce Profiles & Sharing |
| Sync | Custom REST API via Apex |

## Performance Considerations

1. **Lazy Loading** - Load jobs/tasks on-demand
2. **Pagination** - Limit queries to 1000 records
3. **Bulkification** - All Apex follows bulk patterns
4. **Compression** - Images compressed before storage (max 1MB)
5. **Indexing** - IndexedDB indexes on Status__c, Synced__c
6. **Governor Limits** - All operations within Salesforce limits

## Offline Strategy

### What's Stored Offline?
- Assigned jobs and tasks
- Form definitions and fields
- Pending form responses
- Media files (base64, compressed)
- Target record data for "View Data" tasks

### What's NOT Stored?
- User data
- Org-wide reports
- Other users' jobs
- Historical sync logs (only last 5)

## Error Handling

### Network Errors
- Retry with exponential backoff
- Queue for next sync
- User notification

### Data Validation Errors
- Inline field validation
- Server-side validation on sync
- Error messages in ROSE_Form_Response__c.Error_Message__c

### Conflict Errors
- Timestamp comparison
- Conflict queue for manual resolution
- Last write wins by default

## Monitoring & Logging

### ROSE_Sync_Log__c
Tracks every sync operation:
- Start/end time
- Records up/down
- Success/failure status
- Error details

### Admin Dashboard (Future)
- Sync success rate
- Average sync duration
- Pending conflicts
- Field user activity

## Scalability

Current design supports:
- **40 field workers** (current requirement)
- **1000 jobs** per user
- **10,000 tasks** per user
- **100,000 form responses** (rolling cleanup)

Future scaling options:
- Platform Events for real-time sync
- Big Objects for historical data
- Shield for encryption
- Platform Cache for performance

---

*Last updated: 2024*
