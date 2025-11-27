import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

import getAllAIModels from '@salesforce/apex/AIModelAdminController.getAllAIModels';
import testModelConnection from '@salesforce/apex/AIModelAdminController.testModelConnection';
import updateModelStatus from '@salesforce/apex/AIModelAdminController.updateModelStatus';

const COLUMNS = [
    { label: 'Model Name', fieldName: 'Label', type: 'text', sortable: true },
    { label: 'Provider', fieldName: 'Model_Provider__c', type: 'text', sortable: true },
    { label: 'Type', fieldName: 'Model_Type__c', type: 'text', sortable: true },
    {
        label: 'Context Window',
        fieldName: 'Context_Window_Size__c',
        type: 'number',
        sortable: true,
        cellAttributes: { alignment: 'right' }
    },
    {
        label: 'Max Tokens',
        fieldName: 'Max_Tokens__c',
        type: 'number',
        sortable: true,
        cellAttributes: { alignment: 'right' }
    },
    { label: 'Active', fieldName: 'Is_Active__c', type: 'boolean', sortable: true },
    {
        label: 'Cost per Token',
        fieldName: 'Cost_Per_Token__c',
        type: 'currency',
        typeAttributes: { currencyCode: 'USD' },
        cellAttributes: { alignment: 'right' }
    },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'Activate', name: 'activate' },
                { label: 'Deactivate', name: 'deactivate' },
                { label: 'Test', name: 'test' }
            ]
        }
    }
];

const DEFAULT_TEST_PROMPT =
    'Hello, please respond with a simple greeting to confirm connectivity.';

export default class AiModelAdminConfig extends LightningElement {
    @track aiModels = [];
    @track selectedTestModel = '';
    @track testPrompt = DEFAULT_TEST_PROMPT;
    @track testResult = '';
    @track showTestSection = false;
    @track isTestingConnection = false;
    @track sortedBy = 'Label';
    @track sortDirection = 'asc';

    columns = COLUMNS;
    wiredModelsResult;

    // ---------------------------------------------------------
    // Load AI Models
    // ---------------------------------------------------------
    @wire(getAllAIModels)
    wiredModels(result) {
        this.wiredModelsResult = result;

        if (result.data) {
            this.aiModels = result.data;
            this.processModelData();
        } else if (result.error) {
            console.error('Error loading AI models', result.error);
            this.showToast('Error', 'Failed to load AI models', 'error');
        }
    }

    // Add computed properties (id for datatable)
    processModelData() {
        this.aiModels = this.aiModels.map((model) => ({
            ...model,
            id: model.DeveloperName
        }));

        this.showTestSection = this.aiModels.length > 0;
    }

    // Model dropdown options (only active models)
    get modelTestOptions() {
        return this.aiModels
            .filter((model) => model.Is_Active__c)
            .map((model) => ({
                label: `${model.Label} (${model.Model_Provider__c})`,
                value: model.DeveloperName
            }));
    }

    // Disable test button
    get testButtonDisabled() {
        return (
            !this.selectedTestModel ||
            this.isTestingConnection ||
            !this.testPrompt ||
            !this.testPrompt.trim()
        );
    }

    // ---------------------------------------------------------
    // Sorting
    // ---------------------------------------------------------
    handleSort(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;

        const field = this.sortedBy;
        const direction = this.sortDirection === 'asc' ? 1 : -1;

        this.aiModels = [...this.aiModels].sort((a, b) => {
            const aVal = a[field] || '';
            const bVal = b[field] || '';
            return aVal > bVal ? direction : aVal < bVal ? -direction : 0;
        });
    }

    // ---------------------------------------------------------
    // Row Actions (Activate / Deactivate / Test)
    // ---------------------------------------------------------
    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'activate') {
            await this.changeModelStatus(row, true);
        } else if (actionName === 'deactivate') {
            await this.changeModelStatus(row, false);
        } else if (actionName === 'test') {
            this.selectedTestModel = row.DeveloperName;
            await this.handleRunTest();
        }
    }

    async changeModelStatus(row, isActive) {
        try {
            await updateModelStatus({
                modelId: row.DeveloperName,
                isActive: isActive
            });

            this.showToast(
                'Success',
                `Model ${row.Label} is now ${isActive ? 'Active' : 'Inactive'}`,
                'success'
            );

            await refreshApex(this.wiredModelsResult);
        } catch (error) {
            console.error('Error updating model status', error);
            this.showToast('Error', 'Failed to update model status', 'error');
        }
    }

    // ---------------------------------------------------------
    // Test Model Section
    // ---------------------------------------------------------
    handleTestModelChange(event) {
        this.selectedTestModel = event.detail.value;
    }

    handleTestPromptChange(event) {
        this.testPrompt = event.detail.value;
    }

    async handleRunTest() {
        if (!this.selectedTestModel) {
            this.showToast('Warning', 'Please select a model to test', 'warning');
            return;
        }

        this.isTestingConnection = true;
        this.testResult = '';

        try {
            const result = await testModelConnection({
                modelId: this.selectedTestModel
            });

            this.testResult = result;

            if (result && result.startsWith('SUCCESS')) {
                this.showToast('Success', 'Model connection successful', 'success');
            } else {
                this.showToast('Error', 'Model connection failed', 'error');
            }
        } catch (error) {
            console.error('Error testing model connection', error);
            this.showToast('Error', 'Failed to test model connection', 'error');
        } finally {
            this.isTestingConnection = false;
        }
    }

    // ---------------------------------------------------------
    // Toast Helper
    // ---------------------------------------------------------
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}
