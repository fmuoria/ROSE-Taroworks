/**
 * Service class for form definition and processing operations
 */
public with sharing class ROSEFormService {
    
    /**
     * Get all active form definitions
     * @return List of active form definitions
     */
    @AuraEnabled(cacheable=true)
    public static List<ROSE_Form_Definition__c> getActiveFormDefinitions() {
        try {
            return [
                SELECT Id, Name, Target_Object__c, Version__c, Active__c, Description__c
                FROM ROSE_Form_Definition__c
                WHERE Active__c = true
                ORDER BY Name
                LIMIT 1000
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching form definitions: ' + e.getMessage());
        }
    }
    
    /**
     * Get form fields for a specific form definition
     * @param formDefinitionId ID of the form definition
     * @return List of form fields ordered by display order
     */
    @AuraEnabled(cacheable=true)
    public static List<ROSE_Form_Field__c> getFormFields(Id formDefinitionId) {
        try {
            if (formDefinitionId == null) {
                throw new IllegalArgumentException('Form Definition ID is required');
            }
            
            return [
                SELECT Id, Name, Field_API_Name__c, Field_Label__c, Field_Type__c,
                       Required__c, Display_Order__c, Validation_Rule__c,
                       Conditional_Logic__c, Picklist_Values__c, Default_Value__c,
                       Help_Text__c, ROSE_Form_Definition__c
                FROM ROSE_Form_Field__c
                WHERE ROSE_Form_Definition__c = :formDefinitionId
                ORDER BY Display_Order__c NULLS LAST, Name
                LIMIT 1000
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching form fields: ' + e.getMessage());
        }
    }
    
    /**
     * Process form response and create/update target Salesforce record
     * @param response Form response record with response data
     * @return ID of created/updated target record
     */
    public static Id processFormResponse(ROSE_Form_Response__c response) {
        try {
            if (response == null || response.ROSE_Form_Definition__c == null) {
                throw new IllegalArgumentException('Invalid form response');
            }
            
            // Get form definition
            ROSE_Form_Definition__c formDef = [
                SELECT Id, Target_Object__c
                FROM ROSE_Form_Definition__c
                WHERE Id = :response.ROSE_Form_Definition__c
                LIMIT 1
            ];
            
            if (String.isBlank(formDef.Target_Object__c)) {
                throw new IllegalArgumentException('Target object not specified in form definition');
            }
            
            // Parse response data
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response.Response_Data__c);
            
            // Get object describe
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(formDef.Target_Object__c);
            if (targetType == null) {
                throw new IllegalArgumentException('Invalid target object: ' + formDef.Target_Object__c);
            }
            
            // Create or update record
            SObject targetRecord;
            if (String.isNotBlank(response.Target_Record__c)) {
                // Update existing record
                targetRecord = targetType.newSObject(response.Target_Record__c);
            } else {
                // Create new record
                targetRecord = targetType.newSObject();
            }
            
            // Populate fields
            Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
            for (String fieldName : responseData.keySet()) {
                if (fieldMap.containsKey(fieldName)) {
                    Object fieldValue = responseData.get(fieldName);
                    Schema.SObjectField field = fieldMap.get(fieldName);
                    Schema.DisplayType fieldType = field.getDescribe().getType();
                    
                    // Convert value based on field type
                    Object convertedValue = convertValue(fieldValue, fieldType);
                    targetRecord.put(fieldName, convertedValue);
                }
            }
            
            // Upsert record
            Database.UpsertResult result = Database.upsert(targetRecord, false);
            
            if (result.isSuccess()) {
                return result.getId();
            } else {
                throw new DmlException('Failed to upsert record: ' + result.getErrors()[0].getMessage());
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing form response: ' + e.getMessage());
            throw e;
        }
    }
    
    /**
     * Validate form response against field rules
     * @param data Form data as map
     * @param formDefId Form definition ID
     * @return List of validation error messages
     */
    public static List<String> validateFormResponse(Map<String, Object> data, Id formDefId) {
        List<String> errors = new List<String>();
        
        try {
            // Get form fields
            List<ROSE_Form_Field__c> fields = getFormFields(formDefId);
            
            for (ROSE_Form_Field__c field : fields) {
                Object value = data.get(field.Field_API_Name__c);
                
                // Check required fields
                if (field.Required__c && (value == null || String.valueOf(value).trim() == '')) {
                    errors.add(field.Field_Label__c + ' is required');
                    continue;
                }
                
                // Skip further validation if field is empty and not required
                if (value == null || String.valueOf(value).trim() == '') {
                    continue;
                }
                
                // Validate regex pattern
                if (String.isNotBlank(field.Validation_Rule__c)) {
                    String strValue = String.valueOf(value);
                    Pattern p = Pattern.compile(field.Validation_Rule__c);
                    Matcher m = p.matcher(strValue);
                    if (!m.matches()) {
                        errors.add(field.Field_Label__c + ' does not match required format');
                    }
                }
                
                // Type-specific validation
                if (field.Field_Type__c == 'Number') {
                    try {
                        Decimal.valueOf(String.valueOf(value));
                    } catch (Exception e) {
                        errors.add(field.Field_Label__c + ' must be a valid number');
                    }
                } else if (field.Field_Type__c == 'Date') {
                    try {
                        Date.valueOf(String.valueOf(value));
                    } catch (Exception e) {
                        errors.add(field.Field_Label__c + ' must be a valid date');
                    }
                }
            }
            
        } catch (Exception e) {
            errors.add('Validation error: ' + e.getMessage());
        }
        
        return errors;
    }
    
    /**
     * Convert value to appropriate type based on field type
     * @param value Raw value from form
     * @param fieldType Salesforce field type
     * @return Converted value
     */
    private static Object convertValue(Object value, Schema.DisplayType fieldType) {
        if (value == null) {
            return null;
        }
        
        try {
            String strValue = String.valueOf(value);
            
            switch on fieldType {
                when STRING, TEXTAREA, PHONE, EMAIL, URL, ID, REFERENCE {
                    return strValue;
                }
                when INTEGER {
                    return Integer.valueOf(strValue);
                }
                when DOUBLE, CURRENCY, PERCENT {
                    return Decimal.valueOf(strValue);
                }
                when BOOLEAN {
                    return Boolean.valueOf(strValue);
                }
                when DATE {
                    return Date.valueOf(strValue);
                }
                when DATETIME {
                    if (value instanceof DateTime) {
                        return value;
                    }
                    return DateTime.valueOf(strValue);
                }
                when TIME {
                    return Time.newInstance(Integer.valueOf(strValue.split(':')[0]), 
                                           Integer.valueOf(strValue.split(':')[1]), 
                                           0, 0);
                }
                when else {
                    return strValue;
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error converting value: ' + e.getMessage());
            return value;
        }
    }
}
