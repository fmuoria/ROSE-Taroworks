# ROSE TaroWorks - Administrator Guide

## Overview

This guide explains how to configure and manage the ROSE TaroWorks mobile data collection system.

## Creating Form Definitions

### Step 1: Create Form Definition

1. Navigate to **Form Definitions** tab
2. Click **New**
3. Fill in:
   - **Name**: Descriptive name (e.g., "Household Survey")
   - **Target Object**: Salesforce object to create (e.g., "Contact")
   - **Version**: Version number (e.g., "1.0")
   - **Active**: Check to make available to field workers
   - **Description**: Purpose of the form

### Step 2: Add Form Fields

1. Open the Form Definition
2. Click **New** in the Form Fields section
3. For each field, specify:
   - **Field API Name**: API name of the target object field
   - **Field Label**: Label shown to field workers
   - **Field Type**: Text, Number, Date, Picklist, GPS, Photo, Signature
   - **Required**: Check if field is mandatory
   - **Display Order**: Order in which fields appear
   - **Validation Rule**: Optional regex pattern
   - **Picklist Values**: JSON array for picklist options
   - **Default Value**: Pre-populated value
   - **Help Text**: Instructions for field workers

## Creating Jobs and Tasks

### Creating a Job

1. Navigate to **Jobs** tab
2. Click **New**
3. Fill in:
   - **Name**: Job identifier
   - **Assigned User**: Field User to assign
   - **Status**: New
   - **Priority**: High/Medium/Low
   - **Due Date**: Completion deadline
   - **Region**: Geographic area
   - **Description**: Job details

### Creating Tasks

1. Open a Job record
2. Click **New** in the Tasks section
3. Fill in:
   - **Name**: Task name
   - **Task Type**: 
     - View Data: Display record information
     - View Resource: Show a PDF/image
     - Collect Data: Fill out a form
   - **Sequence Order**: Task execution order
   - **Form Definition**: If Collect Data, select form
   - **Instructions**: Guidance for field worker

## Managing Field Workers

### Adding a New Field Worker

1. Create a **Contact** record
2. Create a **Field User** record:
   - Link to Contact via User lookup
   - Set Status to Active
   - Assign Region
   - Enter Phone number

3. Create Salesforce User:
   - License: Customer Community Plus
   - Profile: ROSE Field Worker
   - Link to Contact

## Monitoring Sync Logs

1. Navigate to **Sync Logs** tab
2. Review:
   - **Sync Type**: Full/Metadata/Upload
   - **Status**: Success/Failed
   - **Records Up/Down**: Upload/download counts
   - **Error Details**: Failure reasons

## Resolving Conflicts

1. Navigate to **Conflict Queue** tab
2. For each conflict:
   - Review Server Value vs Device Value
   - Select Resolution: Server Wins/Device Wins
   - Click **Save**

## Best Practices

- **Test forms** with sample data before deploying
- **Limit form fields** to 10-15 for mobile usability
- **Set realistic due dates** considering connectivity
- **Monitor sync logs** daily
- **Train field workers** on offline procedures
- **Backup data** regularly

## Troubleshooting

### Field Workers Can't See Jobs

- Verify job assignment to correct Field User
- Check Field User → User lookup is correct
- Ensure job Status is not "Synced"

### Forms Not Syncing

- Check Sync Logs for errors
- Verify Form Definition is Active
- Ensure field mappings are correct

### Media Not Uploading

- Check file size limits (10MB max recommended)
- Verify ContentVersion permissions
- Review Sync Log error details
