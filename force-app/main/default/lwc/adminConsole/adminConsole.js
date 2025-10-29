import { LightningElement, track, api } from 'lwc';
import getAIModels from '@salesforce/apex/AIModelAdminController.getAllAIModels';
import testModelConnection from '@salesforce/apex/AIModelAdminController.testModelConnection';
import updateModelStatus from '@salesforce/apex/AIModelAdminController.updateModelStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AdminAIModelConsole extends LightningElement {
  @track aiModels = [];
  @track aiModelOptions = [];
  @track selectedModel = '';
  @track isLoading = false;

  // test state
  @track isTestRunning = false;
  @track testResult = '';
  @track testHistory = [];

  // columns for datatable — adjust fields to your data
  columns = [
    { label: 'Name', fieldName: 'label', sortable: true },
    { label: 'Provider', fieldName: 'provider' },
    { label: 'Type', fieldName: 'type' },
    { label: 'Context Window', fieldName: 'contextWindow' },
    { label: 'Status', fieldName: 'isActive', type: 'boolean' },
    {
      type: 'action',
      typeAttributes: { rowActions: [{ label: 'Test', name: 'test' }, { label: 'Toggle Status', name: 'toggle_status' }] }
    }
  ];

  connectedCallback() {
    this.loadModels();
  }

  get lastUpdated() {
    if (!this.aiModels || !this.aiModels.length) return 'n/a';
    return new Date().toLocaleString();
  }

  get testButtonDisabled() {
    return !this.selectedModel || this.isTestRunning;
  }

  async loadModels() {
    this.isLoading = true;
    try {
      const res = await getAIModels();
      // expect res to be array of model records; map to local shape
      this.aiModels = (res || []).map((m) => ({
        id: m.DeveloperName || m.Id,
        label: m.Label || m.name,
        provider: m.Model_Provider__c || m.provider,
        type: m.Model_Type__c || m.type,
        contextWindow: m.Context_Window_Size__c || m.contextWindow,
        isActive: m.Is_Active__c || !!m.isActive,
        raw: m
      }));
      this.aiModelOptions = this.aiModels.map((m) => ({ label: m.label, value: m.id }));
    } catch (err) {
      this.showToast('Error', 'Failed to load AI models: ' + this.extractError(err), 'error');
    } finally {
      this.isLoading = false;
    }
  }

  handleModelSelect(event) {
    this.selectedModel = event.detail.value;
  }

  async handleRefreshModels() {
    await this.loadModels();
    this.showToast('Refreshed', 'Model list refreshed', 'success');
  }

  async handleTestConnection() {
    if (!this.selectedModel) return;
    this.isTestRunning = true;
    this.testResult = '';
    try {
      const r = await testModelConnection({ modelId: this.selectedModel });
      // r expected as string or object
      this.testResult = typeof r === 'string' ? r : JSON.stringify(r);
      // store to test history (simple)
      this.testHistory = [{ id: Date.now(), modelName: this.selectedModel, timestamp: new Date().toLocaleString(), status: 'SUCCESS' }, ...this.testHistory].slice(0, 10);
      this.showToast('Test finished', 'Connection test completed', 'success');
    } catch (err) {
      this.testHistory = [{ id: Date.now(), modelName: this.selectedModel, timestamp: new Date().toLocaleString(), status: 'ERROR' }, ...this.testHistory].slice(0, 10);
      this.showToast('Test failed', this.extractError(err), 'error');
    } finally {
      this.isTestRunning = false;
    }
  }

  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
    if (actionName === 'test') {
      this.selectedModel = row.id;
      this.handleTestConnection();
    } else if (actionName === 'toggle_status') {
      this.toggleModelStatus(row);
    }
  }

  async toggleModelStatus(row) {
    const newStatus = !row.isActive;
    try {
      await updateModelStatus({ modelId: row.id, isActive: newStatus });
      this.showToast('Updated', `Model ${row.label} set to ${newStatus ? 'Active' : 'Inactive'}`, 'success');
      // refresh list
      await this.loadModels();
    } catch (err) {
      this.showToast('Error', this.extractError(err), 'error');
    }
  }

  handleAddModel() {
    // navigate to admin page or open modal (implementation specific)
    this.showToast('Info', 'Add Model not implemented yet', 'info');
  }

  handleOpenConfig() {
    this.showToast('Info', 'Open Config not implemented yet', 'info');
  }

  showToast(title, message, variant = 'info') {
    const evt = new ShowToastEvent({ title, message, variant });
    this.dispatchEvent(evt);
  }

  extractError(err) {
    try {
      if (err && err.body && err.body.message) return err.body.message;
      if (err && err.message) return err.message;
      return JSON.stringify(err);
    } catch (e) {
      return String(err);
    }
  }
}