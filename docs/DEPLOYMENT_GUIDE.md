# ROSE TaroWorks Deployment Guide

## Prerequisites

Before deploying ROSE TaroWorks, ensure you have:

✅ **Salesforce Org**
- Production, Developer, or Sandbox org
- System Administrator access
- Available storage space (minimum 100MB)

✅ **Development Tools**
- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) installed
- Git installed
- Terminal/Command line access

✅ **Optional**
- VS Code with Salesforce extensions
- Node.js (for local development)

## Deployment Steps

### Step 1: Clone Repository

```bash
git clone https://github.com/fmuoria/ROSE-Taroworks.git
cd ROSE-Taroworks
```

### Step 2: Authorize Salesforce Org

```bash
# For production/developer org
sf org login web

# For sandbox
sf org login web --instance-url https://test.salesforce.com
```

### Step 3: Run Deployment Script

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

The script will:
1. Deploy custom objects (9 objects)
2. Deploy Apex classes (10 classes)
3. Run Apex tests (verify 75%+ coverage)
4. Deploy LWC components (5 components)
5. Deploy security configuration

**Estimated time:** 10-15 minutes

### Step 4: Verify Deployment

Check deployment status:
```bash
sf project deploy report
```

Expected output:
- ✅ All objects deployed
- ✅ All classes deployed with tests passing
- ✅ All LWC components deployed
- ✅ Profile and sharing rules deployed

## Post-Deployment Configuration

### 1. Create Field User Records

Navigate to **ROSE Field Users** tab:

1. Click **New**
2. Enter Field User details:
   - Name: Field worker's full name
   - User: Link to Salesforce User record
   - Status: Active
   - Region: Geographic area
   - Phone: Contact number
3. Click **Save**

Repeat for all 40 field workers.

### 2. Build Form Definitions

Navigate to **ROSE Form Definitions** tab:

**Example: Household Survey Form**

1. Create Form Definition:
   - Name: "Household Survey"
   - Target Object: "Contact"
   - Version: 1.0
   - Active: Checked

2. Add Form Fields (related list):
   
   **Field 1:**
   - Field Label: "First Name"
   - Field API Name: "FirstName"
   - Field Type: Text
   - Required: Checked
   - Display Order: 1

   **Field 2:**
   - Field Label: "Last Name"
   - Field API Name: "LastName"
   - Field Type: Text
   - Required: Checked
   - Display Order: 2

   **Field 3:**
   - Field Label: "Email"
   - Field API Name: "Email"
   - Field Type: Text
   - Required: Unchecked
   - Display Order: 3
   - Validation Rule: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$`

### 3. Create Jobs and Tasks

Navigate to **ROSE Jobs** tab:

1. Create Job:
   - Name: "Community Survey - District 1"
   - Assigned User: Select Field User
   - Status: New
   - Priority: High
   - Due Date: Next week
   - Region: North

2. Add Tasks (related list):
   
   **Task 1:**
   - Name: "Review Instructions"
   - Task Type: View Resource
   - Resource URL: Link to instructions PDF
   - Sequence Order: 1

   **Task 2:**
   - Name: "Collect Household Data"
   - Task Type: Collect Data
   - Form Definition: Select "Household Survey"
   - Sequence Order: 2

### 4. Configure Experience Cloud (Community)

#### Create Community Site

1. Go to **Setup** → **Digital Experiences** → **All Sites**
2. Click **New**
3. Select **Build Your Own (LWR)** template
4. Name: "ROSE Field App"
5. URL: `rose-field-app`

#### Add LWC Components to Pages

1. In Experience Builder:
   - Add **roseJobList** component to home page
   - Add **roseSyncStatus** component to header
   - Add **roseTaskViewer** as standalone page

2. Set component visibility:
   - Target: Mobile only
   - Profile: ROSE_Field_Worker

#### Enable Mobile Offline (Briefcase)

1. In Experience Builder → Settings → Mobile
2. Enable **Mobile App**
3. Configure Briefcase:
   - Add ROSE_Job__c
   - Add ROSE_Task__c
   - Add ROSE_Form_Definition__c
   - Add ROSE_Form_Field__c
4. Save and publish

### 5. Assign Field Worker Profile

1. Navigate to **Users**
2. Select each field worker user
3. Assign Profile: **ROSE Field Worker**
4. Assign Permission Set: (if any custom permissions)
5. Enable **Salesforce Mobile App** access

### 6. Test the System

#### Desktop Testing

1. Login as field worker
2. Navigate to **ROSE Jobs** tab
3. Verify assigned jobs appear
4. Click a job → verify tasks appear
5. Test sync status component

#### Mobile Testing

1. Install Salesforce Mobile App
2. Login as field worker
3. Navigate to Experience Cloud site
4. Verify jobs load
5. Test offline mode:
   - Turn on airplane mode
   - Create form response
   - Turn off airplane mode
   - Trigger sync
   - Verify data uploaded

## Optional: Sample Data Setup

Run the sample data script:

```bash
chmod +x scripts/setup-sample-data.sh
./scripts/setup-sample-data.sh
```

This creates:
- 3 Field Users
- 1 Form Definition with 3 fields
- 2 Jobs with Tasks

## Troubleshooting

### Deployment Errors

**Error: "No default org authorized"**
```bash
sf org login web
```

**Error: "Test coverage below 75%"**
- Check test results: `sf apex run test --wait 10 --result-format human --code-coverage`
- Fix failing tests
- Redeploy: `./scripts/deploy.sh`

**Error: "Component failures"**
- Check detailed logs: `sf project deploy report --verbose`
- Fix component issues
- Deploy specific metadata: `sf project deploy start --metadata ApexClass:ROSESyncService`

### Post-Deployment Issues

**Field users can't see jobs**
- Verify sharing rules are active
- Check field user User__c lookup is populated
- Verify ROSE_Field_Worker profile permissions

**Forms not syncing**
- Check ROSE_Sync_Log__c for errors
- Verify Internet connectivity
- Check Apex class assignments in profile

**Mobile app crashes**
- Clear app cache
- Reinstall Salesforce Mobile App
- Check browser console for JavaScript errors

## Verification Checklist

Before going live:

- [ ] All Apex tests pass with 75%+ coverage
- [ ] Field User records created and linked to users
- [ ] At least one Form Definition with fields created
- [ ] Sample jobs and tasks created
- [ ] Experience Cloud site published
- [ ] Mobile offline (Briefcase) configured
- [ ] Field workers can login to mobile app
- [ ] Jobs appear in mobile app
- [ ] Sync functionality works (online → offline → online)
- [ ] Form responses create target records (Contact, Case, etc.)
- [ ] Photos/media upload successfully

## Next Steps

1. **Training**
   - Train field workers on mobile app usage
   - Train admins on job/form creation
   - Review User Guide together

2. **Pilot Phase**
   - Start with 5 field workers
   - Monitor for 2 weeks
   - Collect feedback
   - Fix issues

3. **Full Rollout**
   - Deploy to all 40 field workers
   - Monitor sync logs daily
   - Address issues promptly

4. **Optimization**
   - Review performance metrics
   - Optimize forms based on usage
   - Add custom reports/dashboards

## Support

For deployment issues:
- Check logs: `sf project deploy report --verbose`
- Review error messages carefully
- Search GitHub Issues
- Create new issue with error details

---

**Deployment time estimate:** 2-4 hours for complete setup
