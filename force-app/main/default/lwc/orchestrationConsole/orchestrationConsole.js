import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import startWorkflow from '@salesforce/apex/WorkflowOrchestrationController.startWorkflow';
import getOrchestrationStatus from '@salesforce/apex/OrchestrationController.getOrchestrationStatus';

// Constants for polling
const POLLING_INTERVAL_MS = 3000; // Poll every 3 seconds
const TERMINAL_STATUSES = ['COMPLETED', 'FAILED', 'ERROR'];

export default class OrchestrationConsole extends LightningElement {
    // The recordId the orchestration will run against
    @api recordId;
    // An existing run ID to monitor
    @api assemblyRunId;

    @track orchestration;
    @track isLoading = true;
    @track error;

    pollingInterval;
    lastRefreshed;

    // --- LIFECYCLE HOOKS ---

    connectedCallback() {
        if (this.assemblyRunId) {
            this.fetchStatus();
        } else {
            this.isLoading = false;
        }
    }

    disconnectedCallback() {
        this.stopPolling();
    }

    // --- APEX CALLS ---

    /**
     * @description Initiates a new orchestration workflow.
     */
    async handleStart() {
        this.isLoading = true;
        this.error = null;

        try {
            // This calls the existing startWorkflow method @173
            const result = await startWorkflow({
                workflowKey: 'DOCUMENT_LIFECYCLE', // Example key
                payload: { documentId: this.recordId }
            });

            if (result.ok && result.jobId) {
                this.assemblyRunId = result.jobId;
                this.showToast('Success', 'Orchestration workflow has been initiated.', 'success');
                this.startPolling();
            } else {
                throw new Error(result.error || 'Failed to start orchestration job.');
            }
        } catch (error) {
            this.handleError(error, 'Failed to start orchestration.');
            this.isLoading = false;
        }
    }

    /**
     * @description Fetches the current status of the orchestration from the server.
     */
    async fetchStatus() {
        if (!this.assemblyRunId) return;

        try {
            // Assumes an Apex method that returns an OrchestrationResult object @142
            const result = await getOrchestrationStatus({ runId: this.assemblyRunId });
            this.orchestration = this.processOrchestrationData(result);
            this.lastRefreshed = new Date();
            this.error = null;

            // Stop polling if the job has reached a terminal state
            if (TERMINAL_STATUSES.includes(this.orchestration.status)) {
                this.stopPolling();
            } else if (!this.pollingInterval) {
                // If polling isn't already running, start it
                this.startPolling();
            }
        } catch (error) {
            this.handleError(error, 'Failed to retrieve orchestration status.');
            this.stopPolling();
        } finally {
            this.isLoading = false;
        }
    }

    // --- POLLING LOGIC ---

    startPolling() {
        this.stopPolling(); // Ensure no multiple intervals are running
        this.pollingInterval = setInterval(() => {
            this.fetchStatus();
        }, POLLING_INTERVAL_MS);
    }

    stopPolling() {
        if (this.pollingInterval) {
            clearInterval(this.pollingInterval);
            this.pollingInterval = null;
        }
    }

    // --- UI GETTERS & HELPERS ---

    get hasOrchestration() {
        return !!this.orchestration;
    }

    get isRunning() {
        return this.orchestration && !TERMINAL_STATUSES.includes(this.orchestration.status);
    }
    
    get showStartButton() {
        return !this.assemblyRunId || (this.orchestration && !this.isRunning);
    }

    get overallStatusVariant() {
        if (!this.orchestration) return 'inverse';
        switch (this.orchestration.status) {
            case 'COMPLETED': return 'success';
            case 'FAILED':
            case 'ERROR': return 'error';
            default: return 'warning';
        }
    }

    get lastRefreshedFormatted() {
        return this.lastRefreshed ? `Last updated: ${this.lastRefreshed.toLocaleTimeString()}` : '';
    }

    /**
     * @description Processes data from Apex to add UI-specific properties.
     */
    processOrchestrationData(data) {
        const processedData = { ...data };
        processedData.totalOrchestrationTime = data.totalOrchestrationTime || 0;
        processedData.duration = `${(processedData.totalOrchestrationTime / 1000).toFixed(2)}s`;
        
        if (data.phaseResults) {
            processedData.steps = data.phaseResults.map(step => {
                let icon = 'utility:check';
                if (step.status === 'FAILED') icon = 'utility:error';
                if (step.status === 'IN_PROGRESS' || step.status === 'ACTIVE') icon = 'utility:spinner';
                return { ...step, icon };
            });
        }
        return processedData;
    }

    // --- ERROR & TOAST HANDLING ---

    handleError(error, context) {
        this.error = (error.body && error.body.message) ? `${context}: ${error.body.message}` : context;
        console.error(context, error);
        this.showToast('Error', this.error, 'error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}