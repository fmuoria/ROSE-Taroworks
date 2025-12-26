import { LightningElement, api, track } from 'lwc';
import { saveFormResponse } from 'c/roseUtils';

export default class RoseDynamicForm extends LightningElement {
    @api formDefinitionId;
    @api taskId;
    @track formFields = [];
    @track formTitle = 'Form';

    get visibleFields() {
        return this.formFields;
    }

    async handleSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        
        const response = {
            id: 'temp_' + Date.now(),
            taskId: this.taskId,
            formDefinitionId: this.formDefinitionId,
            responseData: JSON.stringify(fields),
            submittedDate: new Date().toISOString(),
            synced: false
        };
        
        await saveFormResponse(response);
    }
}
