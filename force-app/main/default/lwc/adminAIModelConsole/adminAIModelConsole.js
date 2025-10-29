import { LightningElement, track, api } from 'lwc';
import getModels from '@salesforce/apex/AIModelAdminController.getModels';
import testConnection from '@salesforce/apex/AIModelAdminController.testConnection';
import saveModel from '@salesforce/apex/AIModelAdminController.saveModel';
import deleteModel from '@salesforce/apex/AIModelAdminController.deleteModel';

export default class AdminAIModelConsole extends LightningElement {
    @track aiModels = [];
    @track columns = [
        { label: 'Name', fieldName: 'name', sortable: true, type: 'text', editable: true },
        { label: 'Provider', fieldName: 'provider', sortable: true, type: 'text' },
        { label: 'Type', fieldName: 'type', sortable: true, type: 'text' },
        { label: 'Confidence', fieldName: 'confidence', sortable: true, type: 'number' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'View', name: 'view' },
                    { label: 'Edit', name: 'edit' },
                    { label: 'Delete', name: 'delete' }
                ]
            }
        }
    ];

    @track selectedModelId = null;
    @track selectedModel = null;
    @track testPrompt = '';
    @track testRunning = false;
    @track testResult = null;
    @track aiModelOptions = [];

    lastUpdated = null;

    connectedCallback() {
        this.loadModels();
    }

    async loadModels() {
        try {
            const result = await getModels();
            this.aiModels = result || [];
            this.aiModelOptions = this.aiModels.map(m => ({ label: m.name, value: m.id }));
            this.lastUpdated = new Date().toLocaleString();
        } catch (e) {
            this.showToast('Error loading models', this.extractMessage(e), 'error');
        }
    }

    handleModelSelect(evt) {
        this.selectedModelId = evt.detail.value;
        this.selectedModel = this.aiModels.find(m => m.id === this.selectedModelId) || null;
        // if detailed fetch required, call Apex for details here
    }

    handleRefresh() {
        this.loadModels();
    }

    handleCreateModel() {
        // navigate or open modal to create
        this.showToast('Not implemented', 'Create modal not implemented in this scaffold', 'info');
    }

    async handleRunTest() {
        if (!this.selectedModelId) {
            this.showToast('Select a model', 'Please select a model to test', 'warning');
            return;
        }

        this.testRunning = true;
        this.testResult = null;

        try {
            const res = await testConnection({
                modelId: this.selectedModelId,
                prompt: this.testPrompt
            });
            this.testResult = JSON.stringify(res, null, 2);
        } catch (e) {
            this.testResult = this.extractMessage(e);
        } finally {
            this.testRunning = false;
        }
    }

    handlePromptChange(evt) {
        this.testPrompt = evt.target.value;
    }

    async handleRowAction(evt) {
        const action = evt.detail.action.name;
        const row = evt.detail.row;

        if (action === 'view') {
            // view behaviour
        } else if (action === 'edit') {
            // open edit
        } else if (action === 'delete') {
            if (confirm(`Delete model ${row.name}?`)) {
                await this.deleteModel(row.id);
            }
        }
    }

    async deleteModel(id) {
        try {
            await deleteModel({ modelId: id });
            this.showToast('Deleted', 'Model deleted', 'success');
            await this.loadModels();
        } catch (e) {
            this.showToast('Error', this.extractMessage(e), 'error');
        }
    }

    handleSort(evt) {
        const { fieldName, sortDirection } = evt.detail;
        this.aiModels = [...this.aiModels].sort(
            (a, b) =>
                (a[fieldName] > b[fieldName] ? 1 : -1) *
                (sortDirection === 'asc' ? 1 : -1)
        );
    }

    handleInlineSave(evt) {
        // handle inline edits — call saveModel with changed fields
        const draftValues = evt.detail.draftValues;
        // implement saving logic
    }

    handleExport() {
        this.showToast('Export', 'Export not implemented in scaffold', 'info');
    }

    handleBulk() {
        this.showToast('Bulk', 'Bulk actions not implemented', 'info');
    }

    showToast(title, message, variant = 'info') {
        const evt = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(evt);
    }

    extractMessage(err) {
        if (!err) return 'Unknown error';
        if (err.body && err.body.message) return err.body.message;
        if (err.message) return err.message;
        return JSON.stringify(err);
    }

    get testButtonDisabled() {
        return this.testRunning || !this.selectedModelId;
    }

    get testResultClass() {
        if (!this.testResult) return 'slds-text-color_weak';
        return 'slds-text-color_success';
    }

    get testResultIcon() {
        return this.testResult ? 'utility:success' : 'utility:info';
    }

    get testResultTitle() {
        return this.testResult ? 'Test Result' : 'No test run yet';
    }
}