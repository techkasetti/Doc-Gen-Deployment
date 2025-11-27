import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import submitSignature from '@salesforce/apex/SignatureRequestController.submitSignature';
import getSignatureRequest from '@salesforce/apex/SignatureRequestController.getSignatureRequest';

export default class SignaturePad extends LightningElement {
    @api recordId;
    @track documentTitle = '';
    @track selectedMethod = 'draw';
    @track typedSignature = '';
    @track drawnSignatureData = '';
    @track uploadedSignature = '';
    @track signerEmail = '';
    @track signerName = '';
    @track termsAccepted = false;
    @track isLoading = false;
    isDrawing = false;
    canvas;
    ctx;
    lastX = 0;
    lastY = 0;

    get signatureMethodOptions() {
        return [
            { label: 'Draw Signature', value: 'draw' },
            { label: 'Type Name', value: 'type' },
            { label: 'Upload Image', value: 'upload' }
        ];
    }

    get isTypeMethod() { return this.selectedMethod === 'type'; }
    get isDrawMethod() { return this.selectedMethod === 'draw'; }
    get isUploadMethod() { return this.selectedMethod === 'upload'; }
    
    get hasValidSignature() {
        switch (this.selectedMethod) {
            case 'type': return this.typedSignature.trim().length > 0;
            case 'draw': return this.drawnSignatureData.length > 0;
            case 'upload': return this.uploadedSignature.length > 0;
            default: return false;
        }
    }
    
    get isSubmitDisabled() {
        return !this.termsAccepted;
    }

    connectedCallback() {
        if (this.recordId) {
            getSignatureRequest({ requestId: this.recordId })
                .then(result => {
                    this.documentTitle = result.documentTitle;
                    this.signerEmail = result.signerEmail;
                })
                .catch(error => {
                    this.showToast('Error', 'Failed to load signature request details', 'error');
                });
        }
    }

    renderedCallback() {
        if (this.isDrawMethod && !this.canvas) {
            this.initializeCanvas();
        }
    }
    
    initializeCanvas() {
        this.canvas = this.template.querySelector('.signature-canvas');
        if (this.canvas) {
            this.ctx = this.canvas.getContext('2d');
            this.canvas.addEventListener('mousedown', this.startDrawing.bind(this));
            this.canvas.addEventListener('mousemove', this.draw.bind(this));
            this.canvas.addEventListener('mouseup', this.stopDrawing.bind(this));
            this.canvas.addEventListener('mouseout', this.stopDrawing.bind(this));
        }
    }

    handleMethodChange(event) { this.selectedMethod = event.detail.value; }
    handleTypedSignatureChange(event) { this.typedSignature = event.target.value; }
    handleSignerNameChange(event) { this.signerName = event.target.value; }
    handleSignerEmailChange(event) { this.signerEmail = event.target.value; }
    handleTermsChange(event) { this.termsAccepted = event.target.checked; }
    
    startDrawing(event) {
        this.isDrawing = true;
        [this.lastX, this.lastY] = [event.offsetX, event.offsetY];
    }

    draw(event) {
        if (!this.isDrawing) return;
        this.ctx.beginPath();
        this.ctx.moveTo(this.lastX, this.lastY);
        this.ctx.lineTo(event.offsetX, event.offsetY);
        this.ctx.stroke();
        [this.lastX, this.lastY] = [event.offsetX, event.offsetY];
    }

    stopDrawing() {
        if (this.isDrawing) {
            this.isDrawing = false;
            this.drawnSignatureData = this.canvas.toDataURL('image/png');
        }
    }
    
    clearCanvas() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        this.drawnSignatureData = '';
    }

    handleUploadFinished(event) {
        if (event.detail.files.length > 0) {
            const reader = new FileReader();
            reader.onload = () => { this.uploadedSignature = reader.result; };
            reader.readAsDataURL(event.detail.files[0]);
            this.showToast('Success', 'Signature uploaded successfully', 'success');
        }
    }

    async handleSubmitSignature() {
        this.isLoading = true;
        try {
            const signatureData = this.getSignatureData();
            const signerInfo = JSON.stringify({
                signatureMethod: this.selectedMethod,
                signerName: this.signerName,
                signerEmail: this.signerEmail,
                timestamp: new Date().toISOString()
            });

            await submitSignature({
                requestId: this.recordId,
                signatureData: signatureData,
                signerInfo: signerInfo
            });

            this.showToast('Success', 'Signature submitted successfully!', 'success');
            this.dispatchEvent(new CustomEvent('signaturecomplete'));
        } catch (error) {
            this.showToast('Error', 'Failed to submit signature: ' + error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    getSignatureData() {
        switch (this.selectedMethod) {
            case 'type': return `data:text/plain;base64,${btoa(this.typedSignature)}`;
            case 'draw': return this.drawnSignatureData;
            case 'upload': return this.uploadedSignature;
            default: return '';
        }
    }
    
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}