# ROSE TaroWorks - Salesforce Mobile Data Collection System

**Version:** 1.0.0  
**Organization:** ROSE (Nonprofit)  
**License:** MIT

## 🎯 Overview

ROSE TaroWorks is a complete, Salesforce-native offline-first mobile data collection system designed as a cost-effective alternative to TaroWorks. Built for 40 field workers operating in low-connectivity environments, this solution provides robust offline capabilities, seamless sync, and comprehensive data collection features.

### Key Features

✅ **Offline-First Architecture** - Work completely offline, sync when connected  
✅ **Dynamic Form Builder** - Create custom forms without code  
✅ **Job & Task Management** - Organize field work efficiently  
✅ **Media Capture** - Photos, signatures, GPS coordinates  
✅ **Conflict Resolution** - Intelligent sync conflict handling  
✅ **Mobile-Optimized** - Touch-friendly UI for tablets and phones  
✅ **Cost Effective** - Save $4,300-5,100 annually vs TaroWorks

## 💰 Cost Savings

| Solution | Annual Cost (40 users) | 5-Year Cost |
|----------|-------------------------|-------------|
| TaroWorks | $7,500 | $37,500 |
| ROSE TaroWorks (Experience Cloud) | $2,400-3,200 | $12,000-16,000 |
| **Savings** | **$4,300-5,100** | **$21,500-25,500** |

## 🚀 Quick Start

### Prerequisites

- Salesforce org (Production or Developer Edition)
- Salesforce CLI installed
- Admin access to Salesforce
- Node.js (for development)

### Installation (3 Steps)

```bash
# 1. Clone the repository
git clone https://github.com/fmuoria/ROSE-Taroworks.git
cd ROSE-Taroworks

# 2. Authorize your Salesforce org
sf org login web

# 3. Deploy the application
./scripts/deploy.sh
```

That's it! Your ROSE TaroWorks system is deployed.

### Optional: Create Sample Data

```bash
./scripts/setup-sample-data.sh
```

## 📋 What's Included

### Custom Objects (9)
- `ROSE_Field_User__c` - Field staff management
- `ROSE_Job__c` - Work assignments container
- `ROSE_Task__c` - Individual work units
- `ROSE_Form_Definition__c` - Form metadata
- `ROSE_Form_Field__c` - Form field definitions
- `ROSE_Form_Response__c` - Submitted form data
- `ROSE_Media_Attachment__c` - Photos and files
- `ROSE_Sync_Log__c` - Sync history
- `ROSE_Conflict_Queue__c` - Conflict management

### Apex Classes (5 + 5 Tests)
- `ROSESyncService` - Main sync orchestrator
- `ROSEFormService` - Form processing
- `ROSEJobService` - Job/task management
- `ROSEMediaService` - Media uploads
- `ROSEDataTransferObjects` - Data transfer objects

All with 75%+ test coverage

### Lightning Web Components (5)
- `roseJobList` - Job list and filtering
- `roseTaskViewer` - Task navigation
- `roseDynamicForm` - Dynamic form rendering
- `roseMediaCapture` - Photo/GPS capture
- `roseSyncStatus` - Sync indicator and controls

### Security
- ROSE_Field_Worker profile
- Sharing rules for job assignments
- Field-level security

## 📚 Documentation

- [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) - Complete deployment instructions
- [Admin Guide](docs/ADMIN_GUIDE.md) - System administration
- [User Guide](docs/USER_GUIDE.md) - End user instructions
- [Architecture](docs/ARCHITECTURE.md) - Technical architecture

## 🏗️ Architecture

### Data Flow

```
Mobile Device (Offline)
    ↓
IndexedDB (Local Storage)
    ↓
Sync Engine (6 Phases)
    ↓
Salesforce (ROSESyncService)
    ↓
Target Objects (Contact, Case, etc.)
```

### Sync Phases

1. **Authentication** - Validate OAuth token
2. **Metadata Sync** - Download forms and fields
3. **Assignment Sync** - Download jobs and tasks
4. **Data Upload** - Upload form responses
5. **Conflict Resolution** - Handle sync conflicts
6. **Cleanup** - Remove synced data

## 🎨 Use Cases

### Scenario 1: Beneficiary Registration
Field worker visits rural communities, collects household data offline, syncs when back in office. Data creates Contact records in Salesforce.

### Scenario 2: Service Delivery
Field worker delivers services, captures photos, signatures, and GPS. Creates Case records with attachments.

### Scenario 3: Survey Collection
Field worker conducts surveys using dynamic forms, data syncs to custom objects for reporting.

## 🔧 Configuration

### Post-Deployment Setup

1. **Create Field Users**
   - Navigate to ROSE Field Users tab
   - Create records for each field worker
   - Link to Salesforce User

2. **Build Forms**
   - Create ROSE Form Definition
   - Add ROSE Form Fields with proper types
   - Set validation rules and conditional logic

3. **Assign Work**
   - Create ROSE Jobs
   - Add ROSE Tasks with forms
   - Assign to Field Users

4. **Enable Mobile**
   - Configure Experience Cloud
   - Add LWC components to pages
   - Enable Mobile Offline (Briefcase)

See [Admin Guide](docs/ADMIN_GUIDE.md) for details.

## 🤝 Contributing

We welcome contributions! Guidelines:
- Follow existing code style
- Add tests for new features
- Update documentation
- Use ROSE_ prefix for all custom objects
- Use ROSE prefix for all Apex classes

### Development Setup

```bash
# Clone repo
git clone https://github.com/fmuoria/ROSE-Taroworks.git
cd ROSE-Taroworks

# Create scratch org
sf org create scratch --definition-file config/project-scratch-def.json --alias rose-dev

# Push source
sf project deploy start --target-org rose-dev

# Open org
sf org open --target-org rose-dev
```

## 📞 Support

- GitHub Issues: [Report bugs or request features](https://github.com/fmuoria/ROSE-Taroworks/issues)
- Documentation: Check the `docs/` folder

## 📜 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- Built for ROSE nonprofit organization
- Inspired by TaroWorks functionality
- Community contributions welcomed

## 🗺️ Roadmap

- [ ] Multi-language support (i18n)
- [ ] Advanced reporting dashboard
- [ ] Bulk data import/export
- [ ] Integration with WhatsApp/SMS
- [ ] AI-powered form validation
- [ ] Offline map support

---

**Built with ❤️ for nonprofits doing amazing work in the field**