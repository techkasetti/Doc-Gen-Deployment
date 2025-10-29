import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// Import the Apex method for generating suggestions
import generateClauseSuggestions from '@salesforce/apex/AIEnhancementService.generateClauseSuggestions';

export default class AiClauseSuggest extends LightningElement {
    @api recordId; // Document ID passed to the component
    @api clauseType; // The type of clause to suggest (e.g., 'Termination')
    @api jurisdiction; // The jurisdiction for the clause (e.g., 'US', 'EU')

    @track suggestions = [];
    @track isLoading = false;
    @track error;

    // Automatically fetch suggestions when the component loads
    connectedCallback() {
        if (this.recordId && this.clauseType && this.jurisdiction) {
            this.handleSuggest();
        }
    }

    // Handles the button click to generate suggestions
    @api
    async handleSuggest() {
        this.isLoading = true;
        this.error = undefined;
        this.suggestions = [];

        try {
            // Call the Apex method to get suggestions from the AI service (@464, @1999)
            const result = await generateClauseSuggestions({
                documentId: this.recordId,
                clauseType: this.clauseType,
                jurisdiction: this.jurisdiction
            });

            if (result && result.length > 0) {
                this.suggestions = result.map((item, index) => ({ id: `sugg-${index}`, text: item }));
            } else {
                this.showToast('No Suggestions', 'The AI could not generate suggestions for the given context.', 'info');
            }
        } catch (error) {
            this.error = error;
            this.showToast('Error', 'An error occurred while generating suggestions.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Dispatches an event when a user selects a clause
    handleSelectClause(event) {
        const selectedText = event.target.dataset.text;
        const selectEvent = new CustomEvent('clauseselect', {
            detail: {
                clauseText: selectedText
            }
        });
        this.dispatchEvent(selectEvent);
        this.showToast('Success', 'Clause selected and copied!', 'success');
    }
    
    // Utility function to show toast messages
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}