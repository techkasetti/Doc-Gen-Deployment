import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getAllAIModels from '@salesforce/apex/AIModelAdminController.getAllAIModels';
import testModelConnection from '@salesforce/apex/AIModelAdminController.testModelConnection';
import updateModelStatus from '@salesforce/apex/AIModelAdminController.updateModelStatus';
import deleteModel from '@salesforce/apex/AIModelAdminController.deleteModel';

// --- Constants for cleaner code ---
const TOAST_VARIANTS = { SUCCESS: 'success', WARNING: 'warning', ERROR: 'error', INFO: 'info' };
const TEST_MESSAGES = {
    TESTING: 'Testing connection, please wait...',
    SUCCESS_PREFIX: 'SUCCESS:',
    ERROR_PREFIX: 'ERROR:'
};

const COLUMNS = [
    { label: 'Model Name', fieldName: 'Label', type: 'text', sortable: true },
    { label: 'Provider', fieldName: 'Model_Provider__c', type: 'text', sortable: true },
    { label: 'Status', fieldName: 'statusLabel', type: 'text', sortable: true, cellAttributes: { class: { fieldName: 'statusClass' }, iconName: { fieldName: 'statusIcon' }, iconPosition: 'left' } },
    { label: 'Context Window', fieldName: 'Context_Window_Size__c', type: 'number', sortable: true },
    { label: 'Cost per Token', fieldName: 'Cost_Per_Token__c', type: 'currency', typeAttributes: { currencyCode: 'USD' } },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'Toggle Active/Inactive', name: 'toggle' },
                { label: 'Test', name: 'test' },
                { label: 'View Details', name: 'view' },
                { label: 'Edit', name: 'edit' },
                { label: 'Delete', name: 'delete' }
            ]
        }
    }
];

const DEFAULT_TEST_PROMPT = 'Hello, please respond with a simple greeting to confirm connectivity.';

export default class AiModelAdminConfig extends LightningElement {
    // --- State management ---
    @track aiModels = [];
    @track selectedTestModel = '';
    @track testPrompt = DEFAULT_TEST_PROMPT;
    @track testResult = '';
    @track testMetrics = null;
    @track testHistory = [];
    @track showTestSection = false;
    @track showTestHistory = false;
    @track showHelp = false;
    @track isTestRunning = false;
    @track sortedBy = 'Label';
    @track sortedDirection = 'asc';
    @track lastUpdated = '';

    // --- Configuration ---
    columns = COLUMNS;
    wiredModelsResult;

    // --- Component lifecycle ---
    connectedCallback() {
        this.updateLastUpdatedTime();
        this.loadTestHistory();
    }

    // --- Wire method for loading AI models ---
    @wire(getAllAIModels)
    wiredModels(result) {
        this.wiredModelsResult = result;
        if (result.data) {
            this.aiModels = result.data;
            this.processModelData();
            this.updateLastUpdatedTime();
        } else if (result.error) {
            this.handleError('Failed to load AI models', result.error);
        }
    }

    // --- Data processing and computed properties ---
    processModelData() {
        this.aiModels = this.aiModels.map(model => ({
            ...model,
            id: model.DeveloperName,
            statusLabel: model.Is_Active__c ? 'Active' : 'Inactive',
            statusClass: model.Is_Active__c ? 'slds-text-color_success' : 'slds-text-color_error',
            statusIcon: model.Is_Active__c ? 'utility:success' : 'utility:error'
        }));
        
        this.showTestSection = this.aiModels.length > 0;
        this.showHelp = this.aiModels.length === 0;
    }

    // --- Getters for template binding ---
    get modelCountText() {
        return this.aiModels.length === 1 ? 'model' : 'models';
    }

    get modelTestOptions() {
        return this.aiModels
            .filter(model => model.Is_Active__c)
            .map(model => ({
                label: `${model.Label} (${model.Model_Provider__c})`,
                value: model.DeveloperName
            }));
    }

    get testButtonDisabled() {
        return !this.selectedTestModel || this.isTestRunning || !this.testPrompt?.trim();
    }

    get testResultClass() {
        const baseClass = 'slds-box slds-box_small slds-m-top_medium ';
        if (this.testResult.includes(TEST_MESSAGES.SUCCESS_PREFIX)) {
            return baseClass + 'slds-theme_success';
        } else if (this.testResult.includes(TEST_MESSAGES.ERROR_PREFIX)) {
            return baseClass + 'slds-theme_error';
        }
        return baseClass + 'slds-theme_info';
    }

    get testResultIcon() {
        if (this.testResult.includes(TEST_MESSAGES.SUCCESS_PREFIX)) {
            return 'utility:success';
        } else if (this.testResult.includes(TEST_MESSAGES.ERROR_PREFIX)) {
            return 'utility:error';
        }
        return 'utility:info';
    }

    get testResultIconVariant() {
        return 'inverse';
    }

    get testResultTitle() {
        if (this.testResult.includes(TEST_MESSAGES.SUCCESS_PREFIX)) {
            return 'Connection Successful';
        } else if (this.testResult.includes(TEST_MESSAGES.ERROR_PREFIX)) {
            return 'Connection Failed';
        }
        return 'Test Information';
    }

    // --- Event handlers ---
    handleTestModelSelection(event) {
        this.selectedTestModel = event.detail.value;
        this.clearTestResults();
    }

    handleTestPromptChange(event) {
        this.testPrompt = event.detail.value;
    }

    handleSort(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
    }

    handleRefreshModels() {
        refreshApex(this.wiredModelsResult)
            .then(() => {
                this.showToast('Success', 'Models refreshed successfully', TOAST_VARIANTS.SUCCESS);
                this.updateLastUpdatedTime();
            })
            .catch(error => {
                this.handleError('Failed to refresh models', error);
            });
    }

    // --- Test connection functionality ---
    async handleTestConnection() {
        if (!this.selectedTestModel || !this.testPrompt?.trim()) {
            this.showToast('Warning', 'Please select a model and enter a test prompt', TOAST_VARIANTS.WARNING);
            return;
        }

        const startTime = Date.now();
        this.isTestRunning = true;
        this.testResult = TEST_MESSAGES.TESTING;
        this.testMetrics = null;

        try {
            const result = await testModelConnection({
                modelId: this.selectedTestModel,
                testPrompt: this.testPrompt.trim()
            });
            
            const endTime = Date.now();
            const responseTime = endTime - startTime;
            
            this.testResult = result;
            this.testMetrics = {
                responseTime: responseTime,
                status: result.includes(TEST_MESSAGES.SUCCESS_PREFIX) ? 'Success' : 'Failed',
                version: this.getModelVersion(this.selectedTestModel),
                timestamp: new Date().toLocaleString()
            };
            
            this.addToTestHistory(this.selectedTestModel, result, responseTime);
            
        } catch (error) {
            this.testResult = `${TEST_MESSAGES.ERROR_PREFIX}: ${this.extractErrorMessage(error)}`;
            this.testMetrics = {
                responseTime: Date.now() - startTime,
                status: 'Error',
                version: 'Unknown',
                timestamp: new Date().toLocaleString()
            };
            this.handleError('Connection test failed', error);
        } finally {
            this.isTestRunning = false;
        }
    }

    // --- Row actions handler ---
    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        try {
            switch (actionName) {
                case 'toggle':
                    await this.toggleModelStatus(row);
                    break;
                case 'test':
                    this.selectedTestModel = row.DeveloperName;
                    await this.handleTestConnection();
                    break;
                case 'view':
                    this.viewModelDetails(row);
                    break;
                case 'edit':
                    this.editModel(row);
                    break;
                case 'delete':
                    await this.deleteModel(row);
                    break;
                default:
                    console.warn('Unknown action:', actionName);
            }
        } catch (error) {
            this.handleError(`Failed to execute action: ${actionName}`, error);
        }
    }

    // --- Model management methods ---
    async toggleModelStatus(model) {
        const newStatus = !model.Is_Active__c;
        await this.updateModelStatus(model.DeveloperName, newStatus);
    }

    async updateModelStatus(modelId, isActive) {
        try {
            await updateModelStatus({ modelId, isActive });
            this.showToast(
                'Success',
                `Model ${isActive ? 'activated' : 'deactivated'} successfully`,
                TOAST_VARIANTS.SUCCESS
            );
            await refreshApex(this.wiredModelsResult);
            this.updateLastUpdatedTime();
        } catch (error) {
            this.handleError('Failed to update model status', error);
        }
    }
    
    viewModelDetails(model) {
        // Placeholder for viewing details in a modal
        console.log('Viewing details for:', model);
        this.showToast('Info', `Viewing details for ${model.Label}`, TOAST_VARIANTS.INFO);
    }
    
    editModel(model) {
        // Placeholder for opening an edit modal
        console.log('Editing model:', model);
        this.showToast('Info', `Edit functionality for ${model.Label} would open here`, TOAST_VARIANTS.INFO);
    }

    async deleteModel(model) {
        // Placeholder for deleting with confirmation
        console.log('Deleting model:', model);
        // In a real app, show a confirmation modal before calling Apex
        try {
            await deleteModel({ modelId: model.DeveloperName });
            this.showToast('Success', `Model ${model.Label} deleted successfully`, TOAST_VARIANTS.SUCCESS);
            await refreshApex(this.wiredModelsResult);
        } catch(error) {
            this.handleError('Failed to delete model', error);
        }
    }

    // --- Utility methods ---
    clearTestResults() {
        this.testResult = '';
        this.testMetrics = null;
    }

    updateLastUpdatedTime() {
        this.lastUpdated = new Date().toLocaleString();
    }

    getModelVersion(modelId) {
        // Placeholder to get a version - you could add this to your metadata
        const model = this.aiModels.find(m => m.DeveloperName === modelId);
        return model?.Version__c || 'v1.0';
    }

    addToTestHistory(modelId, result, responseTime) {
        const model = this.aiModels.find(m => m.DeveloperName === modelId);
        const historyEntry = {
            id: Date.now().toString(),
            modelName: model?.Label || modelId,
            status: result.includes(TEST_MESSAGES.SUCCESS_PREFIX) ? 'Success' : 'Failed',
            statusClass: result.includes(TEST_MESSAGES.SUCCESS_PREFIX) ? 
                'slds-text-color_success' : 'slds-text-color_error',
            responseTime: responseTime,
            timestamp: new Date().toLocaleTimeString()
        };
        
        this.testHistory = [historyEntry, ...this.testHistory.slice(0, 9)]; // Keep last 10 entries
        this.showTestHistory = this.testHistory.length > 0;
    }

    loadTestHistory() {
        // You could enhance this to load history from localStorage
        this.testHistory = [];
        this.showTestHistory = false;
    }

    extractErrorMessage(error) {
        if (error?.body?.message) {
            return error.body.message;
        }
        if (error?.message) {
            return error.message;
        }
        return 'An unknown error occurred';
    }

    handleError(title, error) {
        console.error(title, error);
        const message = this.extractErrorMessage(error);
        this.showToast(title, message, TOAST_VARIANTS.ERROR);
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant,
            mode: variant === TOAST_VARIANTS.ERROR ? 'sticky' : 'dismissable'
        }));
    }
}
