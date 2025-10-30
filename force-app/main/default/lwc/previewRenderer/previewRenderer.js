import { LightningElement, api } from 'lwc';
import getPreview from '@salesforce/apex/DocumentGenerationController.getPreview';

export default class PreviewRenderer extends LightningElement {
  @api templateId;
  connectedCallback() { this.refreshPreview(); }
  async refreshPreview() {
    // TODO: call Apex getPreview and render
    try {
      const html = await getPreview({ templateId: this.templateId });
      // render into DOM
    } catch (e) { /* handle */ }
  }
}