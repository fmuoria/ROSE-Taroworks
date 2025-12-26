# ROSE TaroWorks - Deployment Guide

## Prerequisites

Before deploying ROSE TaroWorks, ensure you have:

1. **Salesforce CLI** - Install from https://developer.salesforce.com/tools/salesforcecli
2. **Node.js** (v18 or later) - For local development (optional)
3. **Git** - For version control
4. **Salesforce Org** - Developer, Sandbox, or Production org with appropriate licenses

## License Requirements

- **For Admins**: Salesforce Platform license (free for up to 10 users)
- **For Field Workers**: Experience Cloud Customer Community Plus license
  - Cost: ~$10-15/user/month (vs $187.50/user/month for TaroWorks)

## Deployment Steps

### 1. Clone the Repository

```bash
git clone https://github.com/fmuoria/ROSE-Taroworks.git
cd ROSE-Taroworks
```

### 2. Authorize Your Salesforce Org

```bash
sf org login web --alias myorg --set-default
```

This will open a browser window for you to log in to your Salesforce org.

### 3. Run the Deployment Script

```bash
./scripts/deploy.sh myorg
```

The script will:
- Deploy all custom objects
- Deploy Apex classes
- Deploy Lightning Web Components
- Run all Apex tests
- Verify test coverage (must be ≥75%)

### 4. Create Sample Data (Optional)

To test the application with sample data:

```bash
./scripts/setup-sample-data.sh myorg
```

This creates:
- 5 Field User records
- 2 Form Definitions with fields
- 10 Jobs with tasks

### 5. Post-Deployment Configuration

#### A. Create Experience Cloud Site

1. Go to **Setup** → **Digital Experiences** → **All Sites**
2. Click **New** and select **Customer Service** template
3. Name it "ROSE Field App"
4. Activate the site

#### B. Configure Field Worker Profile

1. Go to **Setup** → **Profiles**
2. Clone the "Customer Community Plus User" profile
3. Rename to "ROSE Field Worker"
4. Configure object permissions:
   - Job__c: Read (Own records)
   - Task__c: Read, Edit
   - Form_Response__c: Create, Read, Edit
   - Form_Definition__c, Form_Field__c: Read
   - Media_Attachment__c: Create, Read

#### C. Assign Apex Class Access

In the ROSE Field Worker profile, enable access to:
- RoseSyncService
- RoseFormService
- RoseJobService
- RoseMediaService

#### D. Create Field Worker Users

1. Create a Contact record for each field worker
2. Go to **Setup** → **Users**
3. Click **New User**
4. Select **Customer Community Plus User** license
5. Assign "ROSE Field Worker" profile
6. Associate with the Contact record

## Troubleshooting

### Deployment Fails with "Unknown Object" Error

**Solution**: Deploy objects first, then classes:
```bash
sf project deploy start --source-dir force-app/main/default/objects
sf project deploy start --source-dir force-app/main/default/classes
```

### Test Coverage Below 75%

**Solution**: Run tests individually to identify failures:
```bash
sf apex run test --class-names RoseSyncService_Test --result-format human
```

### LWC Components Not Visible

**Solution**: 
1. Verify deployment: `sf project deploy report`
2. Add components to Experience Builder pages
3. Clear browser cache

## Deployment to Production

1. Create a change set or use unlocked packages
2. Deploy during maintenance window
3. Run full test suite
4. Verify all integrations

## Next Steps

After successful deployment:
1. Read [ADMIN_GUIDE.md](./ADMIN_GUIDE.md) for configuration
2. Read [USER_GUIDE.md](./USER_GUIDE.md) for end-user instructions
3. Train field workers on the mobile app
4. Set up regular sync schedules

## Support

For issues or questions:
- Check [ARCHITECTURE.md](./ARCHITECTURE.md) for system design
- Review GitHub Issues
- Contact: rose-support@example.com
