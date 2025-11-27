import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getDocumentDetailsForViewer from '@salesforce/apex/DocumentGenerationController.getDocumentDetailsForViewer';
import initiateSignatureRequest from '@salesforce/apex/SignatureRequestController.initiateSignatureRequest';

const COLS = [
    { label: 'Action', fieldName: 'Action__c' },
    { label: 'Details', fieldName: 'Details__c', wrapText: true },
    { label: 'Date', fieldName: 'CreatedDate', type: 'date', typeAttributes: { month: 'short', day: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' } },
    { label: 'User', fieldName: 'UserName', type: 'text' }
];

export default class DocumentViewer extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isLoading = true;
    @track documentTitle = 'Document Viewer';
    @track renderedContent;
    @track contentDocumentId;

    // Signature properties
    @track hasSignatureRequest = false;
    @track signatureStatus;
    @track signatureMethod;
    @track signedDate;

    // Audit Trail properties
    @track auditTrails;
    columns = COLS;

    // *** NEW: Check for recordId as soon as the component loads ***
    connectedCallback() {
        if (!this.recordId) {
            // this.recordId = 'a0CfJ00001X9kARUAZ';
            this.isLoading = false;
            this.showToast('Error: Record ID is Missing', 'This component is not receiving the Record ID from the page. Please check the page configuration.', 'error');
        }
    }

    @wire(getDocumentDetailsForViewer, { recordId: '$recordId' })
    wiredDetails({ error, data }) {
        // This wire will only run if recordId is not null
        if (data) {
            this.documentTitle = data.document.Name;
            this.renderedContent = data.renderedContent;
            this.contentDocumentId = data.document.ContentDocumentString__c;

            if (data.signatureRequest) {
                this.hasSignatureRequest = true;
                this.signatureStatus = data.signatureRequest.Status__c;
                this.signatureMethod = data.signatureRequest.Signature_Method__c;
                this.signedDate = data.signatureRequest.SignedDate__c;
            } else {
                this.hasSignatureRequest = false;
            }

            if (data.auditTrails && data.auditTrails.length > 0) {
                this.auditTrails = data.auditTrails.map(row => ({...row, UserName: row.User__r ? row.User__r.Name : 'System' }));
            }
            this.isLoading = false;
        } else if (error) {
            this.showToast('Error', 'Failed to load document details: ' + error.body.message, 'error');
            this.isLoading = false;
        }
    }

    async handleRequestSignature() {
        // ... (rest of the file is unchanged)
        const signerEmail = 'test.signer@example.com';
        if (!signerEmail) {
            this.showToast('Action Required', 'Please provide a signer email.', 'warning');
            return;
        }
        this.isLoading = true;
        try {
            console.log('Record ID for signature request:', this.recordId);
            const signatureRequestId = await initiateSignatureRequest({ documentConfigId: this.recordId, signerEmail: signerEmail, documentTitle: this.documentTitle });
            this.showToast('Success', 'Signature request created successfully!', 'success');
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: signatureRequestId,
                    objectApiName: 'Signature_Request__c',
                    actionName: 'view'
                }
            });
        } catch (error) {
            this.showToast('Error', 'Failed to create signature request: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleDownload() {
        if (this.contentDocumentId) {
            const downloadUrl = `/sfc/servlet.shepherd/document/download/${this.contentDocumentId}`;
            window.open(downloadUrl, '_blank');
        } else {
            this.showToast('Error', 'No document file found to download.', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}