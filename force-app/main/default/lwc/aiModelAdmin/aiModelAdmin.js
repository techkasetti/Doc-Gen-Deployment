import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getModels from '@salesforce/apex/AIModelAdminController.getModels';
import setDefaultModel from '@salesforce/apex/AIModelAdminController.setDefaultModel';

const ACTIONS = [{ label: 'Set as Default', name: 'set_default' }];

const COLUMNS = [
    { label: 'Model Name', fieldName: 'label' },
    { label: 'Provider', fieldName: 'provider' },
    { label: 'Model ID', fieldName: 'modelId' },
    {
        label: 'Is Default?',
        type: 'boolean',
        fieldName: 'isDefault',
        cellAttributes: { iconName: { fieldName: 'defaultIcon' }, iconPosition: 'left' }
    },
    { label: 'Status', fieldName: 'status', cellAttributes: { class: { fieldName: 'statusClass' } } },
    { type: 'action', typeAttributes: { rowActions: ACTIONS } }
];

export default class AiModelAdmin extends LightningElement {
    columns = COLUMNS;
    wiredModelsResult;

    @wire(getModels)
    wiredModels(result) {
        this.wiredModelsResult = result;
    }

    get models() {
        if (this.wiredModelsResult.data) {
            // Process data to add icons and status for the datatable
            return this.wiredModelsResult.data.map(model => ({
                ...model,
                defaultIcon: model.isDefault ? 'utility:check' : 'utility:close',
                status: model.isActive ? 'Active' : 'Inactive',
                statusClass: model.isActive ? 'slds-text-color_success' : 'slds-text-color_error'
            }));
        }
        return [];
    }

    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'set_default') {
            try {
                await setDefaultModel({ developerName: row.developerName });
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `${row.label} is now the default AI model.`,
                        variant: 'success'
                    })
                );
                // Refresh the data to show the change
                return refreshApex(this.wiredModelsResult);
            } catch (error) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error Setting Default',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            }
        }
    }
}