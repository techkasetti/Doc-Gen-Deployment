import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import performFullRecalculation from '@salesforce/apex/Rollup.performFullRecalculation';

export default class MyComponent extends LightningElement {
    @api recordId; // Assumes the component is on a record page to provide context

    @track isLoading = false;
    @track error;

    /**
     * Handles the button click to initiate the rollup recalculation.
     */
    async handleRecalculate() {
        this.isLoading = true;
        this.error = undefined; // Clear previous errors

        try {
            // Call the Apex method, passing the current record's ID
            const result = await performFullRecalculation({ recordId: this.recordId });

            if (result.success) {
                this.showToast('Success', 'Rollup recalculation has been initiated successfully.', 'success');
            } else {
                throw new Error(result.errorMessage);
            }
        } catch (error) {
            this.error = error.body ? error.body.message : error.message;
            this.showToast('Error', `Recalculation failed: ${this.error}`, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Helper function to dispatch a toast event.
     * @param {string} title - The title of the toast.
     * @param {string} message - The message body of the toast.
     * @param {string} variant - The variant (e.g., 'success', 'error', 'warning').
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }
}