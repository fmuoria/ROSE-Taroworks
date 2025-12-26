# ROSE TaroWorks - System Architecture

## Overview

ROSE TaroWorks is an offline-first mobile data collection system built natively on Salesforce, designed to replace TaroWorks at a fraction of the cost.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Mobile Device (Field Worker)          │
│  ┌───────────────────────────────────────────────────┐  │
│  │           Lightning Web Components                 │  │
│  │  ┌──────┐  ┌──────┐  ┌──────┐  ┌──────┐         │  │
│  │  │ Job  │  │ Task │  │ Form │  │ Sync │         │  │
│  │  │ List │  │ View │  │ Data │  │Status│         │  │
│  │  └──────┘  └──────┘  └──────┘  └──────┘         │  │
│  └─────────────────┬─────────────────────────────────┘  │
│                    │                                     │
│  ┌─────────────────▼─────────────────────────────────┐  │
│  │            IndexedDB (Offline Storage)            │  │
│  │  • Jobs  • Tasks  • Forms  • Responses  • Media  │  │
│  └─────────────────┬─────────────────────────────────┘  │
│                    │                                     │
│  ┌─────────────────▼─────────────────────────────────┐  │
│  │              Sync Engine                          │  │
│  │  • Online detection  • Conflict resolution        │  │
│  │  • Auto-sync  • Manual sync  • Queue management   │  │
│  └─────────────────┬─────────────────────────────────┘  │
└────────────────────┼─────────────────────────────────────┘
                     │ HTTPS
                     │ (when online)
┌────────────────────▼─────────────────────────────────────┐
│               Salesforce Platform                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │              Apex Services Layer                   │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐        │  │
│  │  │   Sync   │  │   Form   │  │   Job    │        │  │
│  │  │ Service  │  │ Service  │  │ Service  │        │  │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘        │  │
│  └───────┼─────────────┼─────────────┼───────────────┘  │
│          │             │             │                   │
│  ┌───────▼─────────────▼─────────────▼───────────────┐  │
│  │              Custom Objects                        │  │
│  │  • Field_User__c    • Job__c         • Task__c    │  │
│  │  • Form_Definition__c • Form_Field__c             │  │
│  │  • Form_Response__c   • Media_Attachment__c       │  │
│  │  • Sync_Log__c        • Conflict_Queue__c         │  │
│  └───────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

## Data Model

### Entity Relationship Diagram

```
Field_User__c
    │
    │ (Lookup)
    ▼
Job__c ─────┐
    │       │ (Master-Detail)
    │       ▼
    │   Task__c ─────┐
    │       │        │ (Master-Detail)
    │       │        ▼
    │       │   Form_Response__c ─────┐
    │       │                         │ (Lookup)
    │       │                         ▼
    │       │                    Media_Attachment__c
    │       │
    │       │ (Lookup)
    │       ▼
    │   Form_Definition__c
    │       │
    │       │ (Master-Detail)
    │       ▼
    │   Form_Field__c
    │
    │ (Lookup)
    ▼
Sync_Log__c
```

## Sync Flow

### 6-Phase Sync Process

```
1. Authentication
   └─> Validate OAuth token

2. Metadata Sync (Download)
   └─> Form definitions
   └─> Form fields

3. Assignment Sync (Download)
   └─> Jobs for user
   └─> Tasks for jobs

4. Data Upload
   └─> Form responses
   └─> Media files

5. Conflict Resolution
   └─> Compare timestamps
   └─> Last write wins
   └─> Create conflict queue

6. Cleanup
   └─> Mark jobs as synced
   └─> Log sync event
   └─> Update last sync time
```

## Offline Architecture

### IndexedDB Structure

**Database**: `roseFieldApp`

**Object Stores**:
- `jobs` - Job records
- `tasks` - Task records
- `formDefinitions` - Form metadata
- `formFields` - Field metadata
- `formResponses` - Submitted forms
- `mediaFiles` - Photos/signatures
- `syncQueue` - Pending uploads

**Indexes**:
- `synced` - Filter unsynced records
- `status` - Filter by status
- `jobId` - Get tasks for job
- `formDefinitionId` - Get fields for form

## Security Model

### Access Control

**Field Worker Profile**:
- Job__c: Read (Own)
- Task__c: Read, Edit
- Form_Response__c: Create, Read, Edit (Own)
- Form_Definition__c: Read
- Form_Field__c: Read
- Media_Attachment__c: Create, Read (Own)

**Sharing Rules**:
- Jobs: Criteria-based WHERE Assigned_User__r.User__c = $User.Id
- Tasks/Responses: Controlled by Parent (Master-Detail)

**Field-Level Security**:
- Hide system fields from field workers
- Protect sensitive donor information

## Component Interaction

### Job Completion Flow

```
1. Field Worker opens roseJobList
   └─> Loads jobs from IndexedDB/Salesforce
   
2. Selects job → roseTaskViewer
   └─> Displays tasks in sequence order
   
3. Selects "Collect Data" task → roseDynamicForm
   └─> Renders form from Form_Definition__c
   └─> Validates input using validation.js
   └─> Saves to IndexedDB
   
4. Captures photo → roseMediaCapture
   └─> Uses device camera
   └─> Saves to IndexedDB
   
5. Submits form
   └─> Marks task complete
   └─> Updates job progress
   
6. Goes online → roseSyncStatus
   └─> Auto-triggers sync
   └─> Calls RoseSyncService.performSync()
   └─> Uploads to Salesforce
   └─> Downloads new jobs
```

## Technology Stack

- **Frontend**: Lightning Web Components
- **Backend**: Apex (Salesforce)
- **Offline Storage**: IndexedDB
- **Sync**: Custom sync engine
- **Mobile**: Salesforce Mobile App / Experience Cloud

## Performance Considerations

- **Bulkification**: All Apex uses collections
- **Lazy Loading**: LWCs load data on demand
- **Caching**: Lightning Data Service caching
- **Compression**: JSON compression for large datasets
- **Pagination**: Limit queries to 1000 records

## Scalability

- **40 Field Workers**: Tested and validated
- **1000 Jobs/month**: Handles easily
- **10,000 Form Responses/month**: Within limits
- **API Calls**: <20,000/day (well under limits)
- **Storage**: ~10MB/user/month

## Cost Analysis

**TaroWorks**: $187.50/user/month × 40 = $7,500/month

**ROSE TaroWorks**:
- Experience Cloud: $10/user/month × 40 = $400/month
- **Savings**: $7,100/month ($85,200/year)

## Future Enhancements

- Real-time sync using Platform Events
- Advanced analytics dashboard
- Multi-language support
- Biometric authentication
- Voice-to-text data entry
- Signature capture
- Barcode scanning
