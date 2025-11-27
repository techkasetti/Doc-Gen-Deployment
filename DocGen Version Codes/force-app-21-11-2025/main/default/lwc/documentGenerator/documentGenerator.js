import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getActiveTemplatesForSelection from '@salesforce/apex/DocumentGenerationController.getActiveTemplatesForSelection';
import previewDocument from '@salesforce/apex/DocumentGenerationController.previewDocument';
import generateFinalDocument from '@salesforce/apex/DocumentGenerationController.generateFinalDocument';

export default class DocumentGenerator extends NavigationMixin(LightningElement) {
    @track currentStep = 'step1';
    @track isLoading = false;
    @track selectedTemplateId = '';
    @track jsonData = '{\n  "contact": {\n    "Name": "John Doe",\n    "IsUSCitizen": true\n  }\n}';
    @track templateOptions = [];
    @track previewHtml = '';
    @track validationErrors = [];

    // State for success screen
    @track generationComplete = false;
    @track newRecordId = ''; // Stores the DocumentLifecycleConfiguration__c ID
    @track newContentDocumentId = ''; // NEW: Stores the ContentDocument (File) ID

    get isStep1() { return this.currentStep === 'step1'; }
    get isStep2() { return this.currentStep === 'step2'; }
    get hasValidationErrors() { return this.validationErrors.length > 0; }

    @wire(getActiveTemplatesForSelection)
    wiredTemplates({ error, data }) {
        if (data) {
            this.templateOptions = data.map(template => ({
                label: template.Name,
                value: template.Id
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to load templates.', 'error');
        }
    }

    handleTemplateChange(event) {
        this.selectedTemplateId = event.detail.value;
    }

    handleJsonChange(event) {
        this.jsonData = event.target.value;
    }

    handleBackClick() {
        this.currentStep = 'step1';
        this.previewHtml = '';
        this.validationErrors = [];
    }

    async handlePreviewClick() {
        if (!this.selectedTemplateId || !this.jsonData) {
            this.showToast('Warning', 'Please select a template and provide JSON data.', 'warning');
            return;
        }
        this.isLoading = true;
        try {
            const result = await previewDocument({ templateId: this.selectedTemplateId, jsonData: this.jsonData });
            if (result.success) {
                this.previewHtml = result.renderedContent;
                this.validationErrors = [];
                this.currentStep = 'step2';
            } else {
                this.validationErrors = result.validationErrors;
                this.previewHtml = '';
                this.currentStep = 'step2'; // Go to next step to show errors
            }
        } catch (error) {
            this.validationErrors = [error.body?.message || 'An unknown server error occurred.'];
            this.previewHtml = '';
        } finally {
            this.isLoading = false;
        }
    }

    async handleGenerateClick() {
        this.isLoading = true;
        try {
            const result = await generateFinalDocument({ templateId: this.selectedTemplateId, jsonData: this.jsonData });
            if (result.success && result.recordId) {
                this.showToast('Success', 'Document generated successfully!', 'success');
                // Store both IDs and show the success screen
                this.generationComplete = true;
                this.newRecordId = result.recordId;
                this.newContentDocumentId = result.contentDocumentId;
            } else {
                this.showToast('Error', result.errorMessage, 'error');
            }
        } catch (error) {
            this.showToast('Error', error.body?.message || 'An unknown error occurred.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // UPDATED: Navigates directly to the standard file preview page
    handleViewDocument() {
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                // Pass the ContentDocumentId to the page
                recordIds: this.newContentDocumentId
            }
        });
    }

    // NEW: Handler for the "Download Document" button
    handleDownloadDocument() {
        // Constructs the standard Salesforce file download URL and opens it in a new tab
        const downloadUrl = `/sfc/servlet.shepherd/document/download/${this.newContentDocumentId}`;
        window.open(downloadUrl, '_blank');
    }
    
    // Handler for the "Generate New" button
    handleGenerateNew() {
        this.resetComponent();
        this.showToast('Ready', 'You can now generate a new document.', 'success');
    }

    // Utility method to reset the component's state
    resetComponent() {
        this.currentStep = 'step1';
        this.isLoading = false;
        this.selectedTemplateId = '';
        this.previewHtml = '';
        this.validationErrors = [];
        this.generationComplete = false;
        this.newRecordId = '';
        this.newContentDocumentId = ''; // Also reset the new file ID
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}