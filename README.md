# ROSE TaroWorks

**Mobile Data Collection System for Salesforce NPSP**

A cost-effective, offline-first alternative to TaroWorks, built natively on Salesforce for nonprofit field operations.

[![Salesforce](https://img.shields.io/badge/Salesforce-API%2060.0-blue.svg)](https://developer.salesforce.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-success.svg)]()

## 🎯 Overview

ROSE TaroWorks enables nonprofit field workers to collect data on mobile devices even when offline, eliminating the need for expensive third-party solutions like TaroWorks.

### Key Features

✅ **Offline-First** - Full functionality without internet connection
✅ **Native Salesforce** - Built on Lightning Web Components & Apex
✅ **Cost-Effective** - Save $85,200/year vs TaroWorks
✅ **Mobile Optimized** - Works on any mobile browser
✅ **Auto-Sync** - Automatic data synchronization when online
✅ **Flexible Forms** - Dynamic form builder with conditional logic
✅ **Media Capture** - Photos, GPS, signatures
✅ **Conflict Resolution** - Handles offline data conflicts automatically

## 💰 Cost Savings

| Solution | Cost per User/Month | Total (40 users) | Annual Cost |
|----------|-------------------|------------------|-------------|
| **TaroWorks** | $187.50 | $7,500/month | $90,000 |
| **ROSE TaroWorks** | $10 | $400/month | $4,800 |
| **Savings** | **$177.50** | **$7,100/month** | **$85,200/year** |

## 🚀 Quick Start

### Prerequisites

- Salesforce CLI installed
- Salesforce org (Developer, Sandbox, or Production)
- Node.js 18+ (optional, for local development)

### Installation

```bash
# Clone the repository
git clone https://github.com/fmuoria/ROSE-Taroworks.git
cd ROSE-Taroworks

# Authorize your Salesforce org
sf org login web --alias myorg --set-default

# Deploy to Salesforce
./scripts/deploy.sh myorg

# Create sample data (optional)
./scripts/setup-sample-data.sh myorg
```

### Post-Installation

1. Set up Experience Cloud site
2. Create field worker users
3. Assign ROSE Field Worker profile
4. Configure mobile access

See [DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) for detailed instructions.

## 📱 How It Works

### For Field Workers

1. **Log in** to mobile app on phone/tablet
2. **View jobs** assigned to you
3. **Complete tasks** including forms and photos
4. **Work offline** - all data saves locally
5. **Sync** when you have internet connection

### For Administrators

1. **Create forms** using Form Definition builder
2. **Assign jobs** to field workers by region
3. **Monitor progress** through sync logs
4. **Review data** submitted by field workers
5. **Resolve conflicts** if needed

## 📦 What's Included

### Custom Objects

- `Field_User__c` - Field staff records
- `Job__c` - Work assignments
- `Task__c` - Individual tasks within jobs
- `Form_Definition__c` - Form templates
- `Form_Field__c` - Form field configurations
- `Form_Response__c` - Submitted form data
- `Media_Attachment__c` - Photos and files
- `Sync_Log__c` - Sync event tracking
- `Conflict_Queue__c` - Data conflict management

### Apex Services

- **RoseSyncService** - Sync orchestration
- **RoseFormService** - Form processing
- **RoseJobService** - Job management
- **RoseMediaService** - Media handling

### Lightning Web Components

- **roseJobList** - Job listing and filtering
- **roseTaskViewer** - Task navigation
- **roseDynamicForm** - Dynamic form renderer
- **roseMediaCapture** - Photo/GPS capture
- **roseSyncStatus** - Sync status indicator
- **roseUtils** - Offline storage utilities

## 📚 Documentation

- [Deployment Guide](docs/DEPLOYMENT_GUIDE.md) - Installation and setup
- [Admin Guide](docs/ADMIN_GUIDE.md) - Configuration and management
- [User Guide](docs/USER_GUIDE.md) - Field worker instructions
- [Architecture](docs/ARCHITECTURE.md) - System design and technical details

## 🏗️ Architecture

ROSE TaroWorks uses a **6-phase sync process**:

1. **Authentication** - Validate OAuth token
2. **Metadata Sync** - Download forms
3. **Assignment Sync** - Download jobs/tasks
4. **Data Upload** - Upload form responses
5. **Conflict Resolution** - Handle conflicts
6. **Cleanup** - Mark synced, log events

Data is stored in **IndexedDB** on the device for offline access and synced with Salesforce when online.

See [ARCHITECTURE.md](docs/ARCHITECTURE.md) for full technical details.

## 🔒 Security

- **Profile-based** access control
- **Criteria-based** sharing rules
- **Field-level** security
- **Encrypted** sensitive data
- **OAuth 2.0** authentication

## 🧪 Testing

All Apex classes include test coverage:

```bash
# Run all tests
sf apex run test --target-org myorg --result-format human

# Run specific test class
sf apex run test --class-names RoseSyncService_Test --result-format human
```

**Test Coverage**: 75%+ (Salesforce requirement met)

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📋 Requirements

### Salesforce Licenses

- **Admins**: Salesforce Platform (free for ≤10 users)
- **Field Workers**: Experience Cloud Customer Community Plus

### Browser Support

- Chrome 90+
- Safari 14+
- Firefox 88+
- Edge 90+

## 🎓 Use Cases

Perfect for nonprofits that need:

- Beneficiary registration
- Household surveys
- Program monitoring
- Field assessments
- Distribution tracking
- Impact measurement

## 📞 Support

- **Documentation**: Check the [docs](docs/) folder
- **Issues**: [GitHub Issues](https://github.com/fmuoria/ROSE-Taroworks/issues)
- **Email**: rose-support@example.com

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Built for ROSE nonprofit to enable cost-effective mobile data collection for their field operations.

## 🗺️ Roadmap

- [ ] Barcode scanning
- [ ] Voice-to-text entry
- [ ] Real-time sync with Platform Events
- [ ] Advanced analytics dashboard
- [ ] Multi-language support
- [ ] Biometric authentication

---

**Built with ❤️ for nonprofits doing amazing work in the field**