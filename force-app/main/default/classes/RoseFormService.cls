/**
 * @description Service class for Form metadata and processing operations
 * @author ROSE Team
 * @date 2025
 */
public with sharing class RoseFormService {
    
    /**
     * Get all active form definitions
     * @return List of active form definitions
     */
    public static List<Form_Definition__c> getActiveFormDefinitions() {
        return [
            SELECT Id, Name, Target_Object__c, Version__c, Active__c, Description__c
            FROM Form_Definition__c
            WHERE Active__c = true
            ORDER BY Name
            LIMIT 1000
        ];
    }
    
    /**
     * Get form fields for a specific form definition
     * @param formDefinitionId The ID of the Form_Definition__c record
     * @return List of form fields ordered by display order
     */
    public static List<Form_Field__c> getFormFields(Id formDefinitionId) {
        if (formDefinitionId == null) {
            throw new IllegalArgumentException('Form Definition ID cannot be null');
        }
        
        return [
            SELECT Id, Form_Definition__c, Field_API_Name__c, Field_Label__c,
                   Field_Type__c, Required__c, Display_Order__c, Validation_Rule__c,
                   Conditional_Logic__c, Picklist_Values__c, Default_Value__c, Help_Text__c
            FROM Form_Field__c
            WHERE Form_Definition__c = :formDefinitionId
            ORDER BY Display_Order__c ASC
            LIMIT 1000
        ];
    }
    
    /**
     * Process form response and create/update target record
     * @param response The form response to process
     * @return The ID of the created/updated target record
     */
    public static String processFormResponse(Form_Response__c response) {
        if (response == null) {
            throw new IllegalArgumentException('Form response cannot be null');
        }
        
        // Get form definition to determine target object
        Form_Definition__c formDef = [
            SELECT Target_Object__c
            FROM Form_Definition__c
            WHERE Id = :response.Form_Definition__c
            LIMIT 1
        ];
        
        if (String.isBlank(formDef.Target_Object__c)) {
            return null;
        }
        
        // Parse response data
        Map<String, Object> data = parseResponseData(response.Response_Data__c);
        
        // Create or update target record
        String recordId = createOrUpdateTargetRecord(
            formDef.Target_Object__c,
            response.Target_Record__c,
            data
        );
        
        // Update form response with target record ID
        if (String.isNotBlank(recordId) && recordId != response.Target_Record__c) {
            response.Target_Record__c = recordId;
            response.Synced__c = true;
            response.Sync_Status__c = 'Success';
            update response;
        }
        
        return recordId;
    }
    
    /**
     * Validate form response data against form definition
     * @param data The response data to validate
     * @param formDefId The form definition ID
     * @return Validation result with success flag and error messages
     */
    public static ValidationResult validateFormResponse(Map<String, Object> data, Id formDefId) {
        ValidationResult result = new ValidationResult();
        result.isValid = true;
        result.errors = new List<String>();
        
        if (data == null || data.isEmpty()) {
            result.isValid = false;
            result.errors.add('Response data cannot be empty');
            return result;
        }
        
        List<Form_Field__c> fields = getFormFields(formDefId);
        
        for (Form_Field__c field : fields) {
            // Check required fields
            if (field.Required__c) {
                Object value = data.get(field.Field_API_Name__c);
                if (value == null || String.valueOf(value).trim() == '') {
                    result.isValid = false;
                    result.errors.add(field.Field_Label__c + ' is required');
                }
            }
            
            // Validate field type
            if (data.containsKey(field.Field_API_Name__c)) {
                Object value = data.get(field.Field_API_Name__c);
                if (value != null && !validateFieldType(value, field.Field_Type__c)) {
                    result.isValid = false;
                    result.errors.add(field.Field_Label__c + ' has invalid type');
                }
            }
        }
        
        return result;
    }
    
    /**
     * Parse JSON response data
     * @param responseData JSON string of response data
     * @return Map of field name to value
     */
    private static Map<String, Object> parseResponseData(String responseData) {
        if (String.isBlank(responseData)) {
            return new Map<String, Object>();
        }
        
        try {
            return (Map<String, Object>) JSON.deserializeUntyped(responseData);
        } catch (Exception e) {
            throw new IllegalArgumentException('Invalid JSON response data: ' + e.getMessage());
        }
    }
    
    /**
     * Create or update target Salesforce record
     * @param objectType The API name of the target object
     * @param recordId Existing record ID (null for new record)
     * @param data Field values to set
     * @return The ID of the created/updated record
     */
    private static String createOrUpdateTargetRecord(String objectType, String recordId, Map<String, Object> data) {
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectType);
        
        if (targetType == null) {
            throw new IllegalArgumentException('Invalid object type: ' + objectType);
        }
        
        SObject record;
        
        if (String.isNotBlank(recordId)) {
            record = targetType.newSObject(recordId);
        } else {
            record = targetType.newSObject();
        }
        
        // Set field values
        Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
        
        for (String fieldName : data.keySet()) {
            if (fieldMap.containsKey(fieldName)) {
                Schema.SObjectField field = fieldMap.get(fieldName);
                Schema.DisplayType fieldType = field.getDescribe().getType();
                Object value = data.get(fieldName);
                
                // Convert value based on field type
                if (value != null) {
                    record.put(fieldName, convertValue(value, fieldType));
                }
            }
        }
        
        upsert record;
        return record.Id;
    }
    
    /**
     * Convert value to appropriate type
     * @param value The value to convert
     * @param fieldType The target field type
     * @return Converted value
     */
    private static Object convertValue(Object value, Schema.DisplayType fieldType) {
        String strValue = String.valueOf(value);
        
        switch on fieldType {
            when BOOLEAN {
                return Boolean.valueOf(strValue);
            }
            when INTEGER {
                return Integer.valueOf(strValue);
            }
            when DOUBLE, CURRENCY, PERCENT {
                return Decimal.valueOf(strValue);
            }
            when DATE {
                return Date.valueOf(strValue);
            }
            when DATETIME {
                return DateTime.valueOf(strValue);
            }
            when else {
                return value;
            }
        }
    }
    
    /**
     * Validate field type
     * @param value The value to validate
     * @param fieldType The expected field type
     * @return True if valid
     */
    private static Boolean validateFieldType(Object value, String fieldType) {
        if (value == null) return true;
        
        String strValue = String.valueOf(value);
        
        try {
            switch on fieldType {
                when 'Number' {
                    Decimal.valueOf(strValue);
                }
                when 'Date' {
                    Date.valueOf(strValue);
                }
            }
            return true;
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * Validation result class
     */
    public class ValidationResult {
        @AuraEnabled public Boolean isValid { get; set; }
        @AuraEnabled public List<String> errors { get; set; }
    }
}
