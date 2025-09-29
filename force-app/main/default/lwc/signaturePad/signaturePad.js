import { LightningElement, api, track } from 'lwc';
import submitSignature from '@salesforce/apex/SignatureRequestController.createSignatureRequest';

export default class SignaturePad extends LightningElement {
  @api recordId;
  @track typedSignature = '';
  @track showCanvas = true;
  @track showTyped = false;

  onTypedChange(evt) { this.typedSignature = evt.target.value; }

  async handleSubmit() {
    try {
      await submitSignature({ documentId: this.recordId, signerEmail: 'placeholder@example.com', signerName: 'Tester' });
      this.dispatchEvent(new CustomEvent('success'));
    } catch (err) {
      this.dispatchEvent(new CustomEvent('error', { detail: err }));
    }
  }
}
