/**
 * Form Validation Module
 * Provides client-side validation for form fields
 */

/**
 * Validate a single field value
 */
export function validateField(field, value) {
    const errors = [];

    // Check required
    if (field.required && (!value || value.toString().trim() === '')) {
        errors.push(`${field.fieldLabel} is required`);
        return { valid: false, errors };
    }

    // If value is empty and not required, it's valid
    if (!value || value.toString().trim() === '') {
        return { valid: true, errors: [] };
    }

    // Validate by field type
    switch (field.fieldType) {
        case 'Number':
            if (isNaN(value)) {
                errors.push(`${field.fieldLabel} must be a number`);
            }
            break;

        case 'Date':
            if (!isValidDate(value)) {
                errors.push(`${field.fieldLabel} must be a valid date`);
            }
            break;

        case 'Email':
            if (!isValidEmail(value)) {
                errors.push(`${field.fieldLabel} must be a valid email`);
            }
            break;
    }

    // Apply validation rule (regex) if present
    if (field.validationRule && field.validationRule.trim() !== '') {
        try {
            const regex = new RegExp(field.validationRule);
            if (!regex.test(value)) {
                errors.push(`${field.fieldLabel} does not match required format`);
            }
        } catch (e) {
            console.error('Invalid regex pattern:', e);
        }
    }

    return {
        valid: errors.length === 0,
        errors
    };
}

/**
 * Validate entire form
 */
export function validateForm(fields, formData) {
    const allErrors = [];
    let isValid = true;

    fields.forEach(field => {
        const value = formData[field.fieldApiName];
        const result = validateField(field, value);
        
        if (!result.valid) {
            isValid = false;
            allErrors.push(...result.errors);
        }
    });

    return {
        valid: isValid,
        errors: allErrors
    };
}

/**
 * Check if value is a valid date
 */
function isValidDate(dateString) {
    const date = new Date(dateString);
    return date instanceof Date && !isNaN(date);
}

/**
 * Check if value is a valid email
 */
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

/**
 * Evaluate conditional logic
 * Format: {"field": "fieldName", "operator": "equals", "value": "someValue"}
 */
export function evaluateConditionalLogic(conditionalLogic, formData) {
    if (!conditionalLogic || conditionalLogic.trim() === '') {
        return true; // Always show if no conditional logic
    }

    try {
        const condition = JSON.parse(conditionalLogic);
        const fieldValue = formData[condition.field];

        switch (condition.operator) {
            case 'equals':
                return fieldValue === condition.value;
            case 'notEquals':
                return fieldValue !== condition.value;
            case 'contains':
                return fieldValue && fieldValue.toString().includes(condition.value);
            case 'greaterThan':
                return Number(fieldValue) > Number(condition.value);
            case 'lessThan':
                return Number(fieldValue) < Number(condition.value);
            default:
                return true;
        }
    } catch (e) {
        console.error('Error evaluating conditional logic:', e);
        return true; // Show field if logic evaluation fails
    }
}

/**
 * Parse picklist values from JSON string
 */
export function parsePicklistValues(picklistValuesJson) {
    if (!picklistValuesJson || picklistValuesJson.trim() === '') {
        return [];
    }

    try {
        return JSON.parse(picklistValuesJson);
    } catch (e) {
        console.error('Error parsing picklist values:', e);
        return [];
    }
}
