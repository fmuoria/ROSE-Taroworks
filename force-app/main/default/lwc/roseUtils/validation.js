/**
 * Form validation utilities
 */

/**
 * Validate a single field value
 * @param {*} value Field value
 * @param {Object} fieldMetadata Field metadata from ROSE_Form_Field__c
 * @returns {Object} { valid: boolean, error: string }
 */
export function validateField(value, fieldMetadata) {
    const result = { valid: true, error: null };
    
    // Check required
    if (fieldMetadata.Required__c) {
        if (value === null || value === undefined || value === '') {
            result.valid = false;
            result.error = `${fieldMetadata.Field_Label__c} is required`;
            return result;
        }
    }
    
    // If value is empty and not required, skip further validation
    if (!value && !fieldMetadata.Required__c) {
        return result;
    }
    
    // Validate regex pattern
    if (fieldMetadata.Validation_Rule__c) {
        try {
            const regex = new RegExp(fieldMetadata.Validation_Rule__c);
            if (!regex.test(String(value))) {
                result.valid = false;
                result.error = `${fieldMetadata.Field_Label__c} does not match required format`;
                return result;
            }
        } catch (e) {
            console.error('Invalid regex pattern:', fieldMetadata.Validation_Rule__c);
        }
    }
    
    // Type-specific validation
    switch (fieldMetadata.Field_Type__c) {
        case 'Number':
            if (isNaN(value)) {
                result.valid = false;
                result.error = `${fieldMetadata.Field_Label__c} must be a valid number`;
            }
            break;
            
        case 'Date':
            if (isNaN(Date.parse(value))) {
                result.valid = false;
                result.error = `${fieldMetadata.Field_Label__c} must be a valid date`;
            }
            break;
            
        case 'Email':
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(value)) {
                result.valid = false;
                result.error = `${fieldMetadata.Field_Label__c} must be a valid email`;
            }
            break;
    }
    
    return result;
}

/**
 * Validate entire form data
 * @param {Object} formData Form data as key-value pairs
 * @param {Array} fields Array of field metadata
 * @returns {Object} { valid: boolean, errors: Array<string> }
 */
export function validateForm(formData, fields) {
    const result = { valid: true, errors: [] };
    
    for (const field of fields) {
        const value = formData[field.Field_API_Name__c];
        const fieldResult = validateField(value, field);
        
        if (!fieldResult.valid) {
            result.valid = false;
            result.errors.push(fieldResult.error);
        }
    }
    
    return result;
}

/**
 * Evaluate conditional logic
 * @param {Object} condition Conditional logic object
 * @param {Object} formData Current form data
 * @returns {boolean} True if condition is met
 */
export function evaluateCondition(condition, formData) {
    if (!condition) {
        return true;
    }
    
    try {
        const { field, operator, value } = condition;
        const fieldValue = formData[field];
        
        switch (operator) {
            case 'equals':
                return fieldValue === value;
                
            case 'notEquals':
                return fieldValue !== value;
                
            case 'contains':
                return String(fieldValue).includes(value);
                
            case 'greaterThan':
                return Number(fieldValue) > Number(value);
                
            case 'lessThan':
                return Number(fieldValue) < Number(value);
                
            case 'isEmpty':
                return !fieldValue || fieldValue === '';
                
            case 'isNotEmpty':
                return fieldValue && fieldValue !== '';
                
            default:
                return true;
        }
    } catch (e) {
        console.error('Error evaluating condition:', e);
        return true;
    }
}
