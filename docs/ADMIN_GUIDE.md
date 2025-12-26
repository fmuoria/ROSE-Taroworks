# ROSE TaroWorks Administrator Guide

## Overview

This guide covers day-to-day administration of the ROSE TaroWorks system.

## Managing Field Users

### Create New Field User

1. Navigate to **ROSE Field Users** tab
2. Click **New**
3. Fill required fields:
   - **Name:** Field worker's full name
   - **User:** Select related Salesforce User
   - **Status:** Active
   - **Region:** Assign geographic region
   - **Phone:** Contact number
4. Save

### Deactivate Field User

1. Find field user record
2. Edit
3. Change **Status** to "Inactive"
4. Save

Inactive users won't receive new job assignments.

## Building Forms

### Create Form Definition

**Purpose:** Define what object the form data will create/update

1. Go to **ROSE Form Definitions**
2. Click **New**
3. Enter:
   - **Name:** Descriptive form name
   - **Target Object:** API name (e.g., "Contact", "Case")
   - **Version:** 1.0
   - **Active:** Check to enable
   - **Description:** Form purpose
4. Save

### Add Form Fields

1. From Form Definition record, scroll to **Form Fields** related list
2. Click **New**
3. Configure field:
   - **Field Label:** User-facing label
   - **Field API Name:** Salesforce field API name (must match target object)
   - **Field Type:** Select from: Text, Number, Date, Picklist, GPS, Photo, Signature
   - **Required:** Check if mandatory
   - **Display Order:** Control field sequence (1, 2, 3...)
   - **Validation Rule:** Optional regex pattern
   - **Help Text:** User guidance
4. Save
5. Repeat for all fields

### Example: Contact Collection Form

**Form Definition:**
- Name: "Beneficiary Registration"
- Target Object: "Contact"
- Active: ✓

**Form Fields:**

| Label | API Name | Type | Required | Order |
|-------|----------|------|----------|-------|
| First Name | FirstName | Text | ✓ | 1 |
| Last Name | LastName | Text | ✓ | 2 |
| Email | Email | Text | | 3 |
| Phone | Phone | Text | | 4 |
| Birth Date | Birthdate | Date | | 5 |
| Location | MailingCity | Text | | 6 |

## Creating and Assigning Jobs

### Create Job

1. Go to **ROSE Jobs** tab
2. Click **New**
3. Fill details:
   - **Name:** Descriptive job name
   - **Assigned User:** Select field user
   - **Status:** New
   - **Priority:** High/Medium/Low
   - **Due Date:** Deadline
   - **Region:** Geographic area
   - **Description:** Job details
4. Save

### Add Tasks to Job

1. From Job record, **Tasks** related list
2. Click **New ROSE Task**
3. Configure task:
   - **Name:** Task description
   - **Task Type:**
     - **View Data:** Show existing record
     - **View Resource:** Display instructions/PDF
     - **Collect Data:** Fill out form
   - **Sequence Order:** Task order (0, 1, 2...)
   - **Status:** Pending
   - **Form Definition:** (for Collect Data tasks)
   - **Resource URL:** (for View Resource tasks)
   - **Target Record:** (for View Data tasks)
   - **Instructions:** Additional guidance
4. Save

### Example Job: Community Survey

**Job:**
- Name: "District 1 Household Survey"
- Assigned User: John Doe
- Status: New
- Priority: High
- Due Date: Next Friday

**Tasks:**

| Order | Name | Type | Details |
|-------|------|------|---------|
| 0 | Review Guidelines | View Resource | URL: training-doc.pdf |
| 1 | Survey Household #1 | Collect Data | Form: Household Survey |
| 2 | Survey Household #2 | Collect Data | Form: Household Survey |
| 3 | Survey Household #3 | Collect Data | Form: Household Survey |

## Monitoring Sync Activity

### View Sync Logs

1. Go to **ROSE Sync Logs** tab
2. View recent syncs
3. Check:
   - **Status:** Success/Failed
   - **Start/End Time:** Sync duration
   - **Records Up/Down:** Data volume
   - **Error Details:** Failure reasons

### Identify Issues

**Slow Syncs**
- Check network connectivity in region
- Review records volume (may need batch processing)
- Optimize form complexity

**Failed Syncs**
- Read **Error Details** field
- Common issues:
  - Invalid field values
  - Required fields missing
  - Validation rule failures
  - Duplicate detection

### Sync Metrics to Monitor

- Sync success rate (target: >95%)
- Average sync duration (target: <60 seconds)
- Pending upload count per user (target: <50)

## Resolving Conflicts

### Understanding Conflicts

Conflicts occur when:
- Field worker edits record offline
- Record is modified on server
- Sync attempts to upload changes

### Review Conflict Queue

1. Go to **ROSE Conflict Queue** tab
2. Review conflicts:
   - **Record ID:** Affected record
   - **Object Type:** Object name
   - **Field Name:** Conflicting field
   - **Server Value:** Current server value
   - **Device Value:** Field worker's value
   - **Resolution:** Pending/Server Wins/Device Wins

### Resolve Conflicts

1. Open conflict record
2. Review both values
3. Decide resolution:
   - **Server Wins:** Keep server value, discard device
   - **Device Wins:** Apply device value, overwrite server
4. Update **Resolution** field
5. **Resolved By:** Auto-populated
6. **Resolved Date:** Auto-populated
7. Save

**Best Practice:** Contact field worker before deciding to understand context.

## Reporting

### Recommended Reports

**Field Worker Activity**
- Report Type: ROSE Jobs
- Filters: Assigned User, Date Range
- Columns: Job Name, Status, Completed Date, Tasks Completed
- Group by: Assigned User

**Form Submission Summary**
- Report Type: ROSE Form Responses
- Filters: Submitted Date (Last 30 Days), Sync Status = Success
- Columns: Form Definition, Submitted Date, Task
- Group by: Form Definition

**Sync Performance**
- Report Type: ROSE Sync Logs
- Filters: Start Time (Last 30 Days)
- Columns: Field User, Start Time, End Time, Status, Records Up, Records Down
- Group by: Status

### Create Dashboard

1. Go to **Dashboards** tab
2. Click **New Dashboard**
3. Add components:
   - **Jobs by Status** (Donut chart)
   - **Form Submissions (Last 30 Days)** (Bar chart)
   - **Sync Success Rate** (Gauge)
   - **Active Field Workers** (Metric)

## Maintenance Tasks

### Weekly

- [ ] Review sync logs for failures
- [ ] Resolve pending conflicts
- [ ] Check field worker activity
- [ ] Monitor storage usage

### Monthly

- [ ] Archive old sync logs (>90 days)
- [ ] Review form performance
- [ ] Update form definitions as needed
- [ ] Field worker feedback session

### Quarterly

- [ ] System performance review
- [ ] User training refresher
- [ ] Update documentation
- [ ] Plan new features/forms

## Best Practices

### Form Design

✅ **DO:**
- Keep forms short (10-15 fields max)
- Use clear, simple labels
- Provide help text for complex fields
- Test forms before deploying
- Use appropriate field types

❌ **DON'T:**
- Create forms with 50+ fields
- Use technical jargon in labels
- Skip validation rules
- Assume field workers understand context

### Job Assignment

✅ **DO:**
- Assign jobs based on region
- Set realistic due dates
- Include clear instructions
- Group related tasks together
- Monitor workload balance

❌ **DON'T:**
- Assign 100 jobs to one person
- Set unrealistic deadlines
- Skip task instructions
- Mix unrelated work in one job

### Data Quality

✅ **DO:**
- Use validation rules
- Make key fields required
- Provide picklist values
- Review submitted data regularly
- Train field workers on data quality

❌ **DON'T:**
- Allow free text for structured data
- Skip data validation
- Ignore duplicate records
- Overlook data errors

## Troubleshooting

**Field worker can't see assigned jobs**
1. Check User__c field is populated on Field User record
2. Verify sharing rules are active
3. Confirm profile is ROSE_Field_Worker
4. Check job Status is "New" or "In Progress"

**Forms not appearing in mobile app**
1. Verify Form Definition Active__c = true
2. Check Form Fields exist and have Display Order
3. Confirm mobile app is synced
4. Try manual sync

**Sync keeps failing**
1. Check Error Details in Sync Log
2. Verify network connectivity
3. Review field validations on target object
4. Check for required fields missing in form

## Support Escalation

For issues you can't resolve:

1. Gather details:
   - Error messages
   - Screenshots
   - Steps to reproduce
   - Affected users

2. Check documentation:
   - Deployment Guide
   - Architecture Guide
   - GitHub Issues

3. Create support ticket:
   - Describe issue clearly
   - Include collected details
   - Specify urgency

---

**For additional help, see:** [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) and [USER_GUIDE.md](USER_GUIDE.md)
