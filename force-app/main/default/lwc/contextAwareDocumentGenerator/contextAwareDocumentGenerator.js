import { LightningElement, api, track } from 'lwc';
import getClauseSuggestions from '@salesforce/apex/ClauseSuggestionController.getSuggestions';

export default class AiClauseSuggest extends LightningElement {
    @api recordId; // Assuming the component is on a record page to provide context

    @track suggestions = [];
    @track isLoading = false;
    @track error = null;

    /**
     * Fetches AI-powered clause suggestions from the Apex controller.
     */
    async handleSuggest() {
        if (!this.recordId) {
            this.error = 'A document context (Record ID) is required to get suggestions.';
            return;
        }

        this.isLoading = true;
        this.error = null;
        this.suggestions = []; // Clear previous suggestions

        try {
            // Call the Apex method to get suggestions
            const fetchedData = await getClauseSuggestions({ documentId: this.recordId, k: 5 });

            if (fetchedData && fetchedData.ok) {
                this.suggestions = fetchedData.suggestions.map((text, index) => ({
                    id: `clause_${index}`,
                    text: text,
                    confidence: Math.floor(Math.random() * (98 - 85 + 1)) + 85 // Mock confidence
                }));
            } else {
                throw new Error(fetchedData.message || 'No suggestions were returned.');
            }

        } catch (e) {
            console.error('Error fetching suggestions:', e);
            this.error = e.body ? e.body.message : e.message;
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * Handles the click event for copying a clause to the clipboard.
     */
    handleCopy(event) {
        const clauseText = event.target.dataset.text;
        navigator.clipboard.writeText(clauseText).then(() => {
            // Optionally, dispatch a toast event to confirm copy
            console.log('Clause copied to clipboard.');
        }).catch(err => {
            console.error('Failed to copy clause: ', err);
        });
    }
}