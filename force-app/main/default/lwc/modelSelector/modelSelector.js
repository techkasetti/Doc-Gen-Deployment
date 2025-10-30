import { LightningElement, api, track, wire } from 'lwc';
import getAllAIModels from '@salesforce/apex/AIModelAdminController.getAllAIModels';

/**
 * A reusable component for selecting an available AI model.
 * It fetches model data from the AI_Model_Configuration__mdt custom metadata type
 * and dispatches an event when a model is selected.
 */
export default class ModelSelector extends LightningElement {
    /**
     * The label for the combobox. Can be set by a parent component.
     * @type {string}
     */
    @api label = 'Select an AI Model';

    /**
     * The ID of the currently selected model. Can be pre-set by a parent.
     * @type {string}
     */
    @api selectedModelId;

    /**
     * Disables the combobox if set to true.
     * @type {boolean}
     */
    @api disabled = false;

    // Internal component state
    @track modelOptions = [];
    @track error;
    isLoading = true;

    /**
     * Wires the component to the Apex method to fetch all AI model configurations.
     * @param {object} result - The result object from the wire service, containing data or an error.
     */
    @wire(getAllAIModels)
    wiredModels({ error, data }) {
        if (data) {
            // Map the retrieved model data to the format required by lightning-combobox
            this.modelOptions = data
                .filter(model => model.Is_Active__c) // Only show active models
                .map(model => ({
                    label: `${model.Label} (${model.Model_Provider__c})`,
                    value: model.DeveloperName // Use DeveloperName as the unique ID
                }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.modelOptions = [];
        }
        this.isLoading = false;
    }

    /**
     * Handles the change event from the combobox when a user selects a model.
     * Dispatches a custom 'modelselect' event with the selected model's ID.
     * @param {Event} event - The selection change event.
     */
    handleSelectionChange(event) {
        this.selectedModelId = event.detail.value;

        // Create and dispatch a custom event to notify parent components of the selection
        const selectionEvent = new CustomEvent('modelselect', {
            detail: { modelId: this.selectedModelId }
        });
        this.dispatchEvent(selectionEvent);
    }

    // --- GETTERS FOR TEMPLATE LOGIC ---

    /**
     * Dynamically determines card body classes based on loading state.
     * @returns {string}
     */
    get cardBodyClasses() {
        return `slds-card__body slds-card__body_inner ${this.isLoading ? 'loading' : ''}`;
    }

    /**
     * Checks if there are any models to display.
     * @returns {boolean} - True if models are available.
     */
    get hasModels() {
        return this.modelOptions && this.modelOptions.length > 0;
    }

    /**
     * Formats the error for user-friendly display.
     * @returns {string}
     */
    get formattedError() {
        if (this.error?.body?.message) {
            return this.error.body.message;
        }
        if (this.error?.message) {
            return this.error.message;
        }
        return 'An unknown error occurred.';
    }
}