import { LightningElement, api, track, wire } from 'lwc';
import getPreview from '@salesforce/apex/DocumentGenerationController.preview';

export default class Preview extends LightningElement {
    /**
     * The ID of the document template to be previewed.
     * This is passed from the parent component.
     */
    @api templateId;

    /**
     * The ID of the record context (e.g., Opportunity, Account) to provide data for the preview.
     * This is also passed from the parent component.
     */
    @api recordId;

    // Internal state for the component
    @track previewUrl;
    @track previewContent;
    @track error;
    @track isLoading = true;

    /**
     * Wires the getPreview Apex method to this property.
     * The method is called automatically when templateId or recordId changes.
     * @param {Id} templateId - The ID of the template.
     * @param {Map<String, Object>} data - A map representing the record data (here, a simplified recordId).
     */
    @wire(getPreview, { templateId: '$templateId', data: { recordId: '$recordId' } })
    wiredPreview({ error, data }) {
        this.isLoading = true;
        if (data) {
            if (data.ok && data.previewUrl) {
                this.previewUrl = data.previewUrl;
                this.previewContent = null;
                this.error = null;
            } else if (data.ok && data.content) { // Fallback for raw content
                this.previewContent = data.content;
                this.previewUrl = null;
                this.error = null;
            }
            else {
                this.error = data.message || 'An unknown error occurred while generating the preview.';
                this.previewUrl = null;
                this.previewContent = null;
            }
        } else if (error) {
            this.error = 'Failed to connect to the preview service. ' + (error.body ? error.body.message : error.message);
            this.previewUrl = null;
            this.previewContent = null;
        }
        this.isLoading = false;
    }

    /**
     * Getter to determine if the preview should be rendered in an iframe.
     */
    get isUrlPreview() {
        return this.previewUrl != null;
    }

    /**
     * Getter to determine if the preview is raw text content.
     */
    get isContentPreview() {
        return this.previewContent != null;
    }

    /**
     * Getter to determine if a preview is available to display.
     */
    get hasPreview() {
        return this.isUrlPreview || this.isContentPreview;
    }
}