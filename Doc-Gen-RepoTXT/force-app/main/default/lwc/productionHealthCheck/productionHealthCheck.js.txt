
// version 3

// import { LightningElement, track } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import validateSystemHealth from '@salesforce/apex/ProductionValidationService.validateSystemHealth';
// import performEndToEndTest from '@salesforce/apex/ProductionValidationService.performEndToEndTest';

// export default class ProductionHealthCheck extends LightningElement {
//     @track healthData;
//     @track isLoading = false;
//     @track errorMessage;
//     @track testResults;
//     @track lastCheckedFormatted;
//     @track overallHealthText = 'Unknown';
//     @track overallHealthClass = 'slds-media slds-p-around_small';
//     @track overallHealthIcon = 'utility:question';
//     @track overallHealthVariant = 'inverse';

//     connectedCallback() {
//         this.refreshHealthCheck();
//     }

//     async refreshHealthCheck() {
//         this.isLoading = true;
//         this.errorMessage = null;
//         this.testResults = null;
        
//         try {
//             const result = await validateSystemHealth();
            
//             if (result.error) {
//                 this.errorMessage = result.error;
//                 this.overallHealthText = 'Error';
//                 this.overallHealthClass = 'slds-media slds-p-around_small slds-theme_error';
//                 this.overallHealthIcon = 'utility:error';
//                 this.overallHealthVariant = 'error';
//             } else {
//                 this.healthData = result;
//                 this.lastCheckedFormatted = this.formatDateTime(result.lastChecked);
//                 this.updateOverallHealthStatus(result.overallHealth);
//             }
//         } catch (error) {
//             this.errorMessage = 'Failed to check system health: ' + error.body?.message || error.message;
//             console.error('Health check error:', error);
//         } finally {
//             this.isLoading = false;
//         }
//     }

//     async runEndToEndTest() {
//         this.isLoading = true;
//         this.testResults = null;
        
//         try {
//             const result = await performEndToEndTest();
//             this.testResults = result;
            
//             if (result.startsWith('SUCCESS')) {
//                 this.showToast('Success', 'End-to-end test completed successfully', 'success');
//             } else {
//                 this.showToast('Test Failed', result, 'error');
//             }
//         } catch (error) {
//             this.testResults = 'FAILED: ' + (error.body?.message || error.message);
//             this.showToast('Error', 'Failed to run end-to-end test', 'error');
//             console.error('End-to-end test error:', error);
//         } finally {
//             this.isLoading = false;
//         }
//     }

//     updateOverallHealthStatus(isHealthy) {
//         if (isHealthy) {
//             this.overallHealthText = 'Healthy';
//             this.overallHealthClass = 'slds-media slds-p-around_small slds-theme_success';
//             this.overallHealthIcon = 'utility:success';
//             this.overallHealthVariant = 'success';
//         } else {
//             this.overallHealthText = 'Issues Detected';
//             this.overallHealthClass = 'slds-media slds-p-around_small slds-theme_warning';
//             this.overallHealthIcon = 'utility:warning';
//             this.overallHealthVariant = 'warning';
//         }
//     }

//     formatDateTime(dateTime) {
//         if (!dateTime) return 'Never';
//         return new Date(dateTime).toLocaleString();
//     }

//     get getStatusClass() {
//         return this.healthData?.customObjects?.isHealthy ? 'slds-media slds-text-color_success' : 'slds-media slds-text-color_error';
//     }

//     get getStatusIcon() {
//         return this.healthData?.customObjects?.isHealthy ? 'utility:success' : 'utility:error';
//     }

//     get hasMissingObjects() {
//         return this.healthData?.customObjects?.missingObjects?.length > 0;
//     }

//     get getPermissionStatusClass() {
//         return this.healthData?.permissions?.isHealthy ? 'slds-media slds-text-color_success' : 'slds-media slds-text-color_error';
//     }

//     get getPermissionStatusIcon() {
//         return this.healthData?.permissions?.isHealthy ? 'utility:success' : 'utility:error';
//     }

//     get hasMissingPermissions() {
//         return this.healthData?.permissions?.missingPermissionSets?.length > 0;
//     }

//     get getTemplateStatusClass() {
//         return this.healthData?.templates?.isHealthy ? 'slds-media slds-text-color_success' : 'slds-media slds-text-color_error';
//     }

//     get getTemplateStatusIcon() {
//         return this.healthData?.templates?.isHealthy ? 'utility:success' : 'utility:error';
//     }

//     get getComplianceStatusClass() {
//         return this.healthData?.complianceRules?.isHealthy ? 'slds-media slds-text-color_success' : 'slds-media slds-text-color_error';
//     }

//     get getComplianceStatusIcon() {
//         return this.healthData?.complianceRules?.isHealthy ? 'utility:success' : 'utility:error';
//     }

//     get testResultClass() {
//         if (!this.testResults) return '';
//         return this.testResults.startsWith('SUCCESS') ? 'slds-media slds-text-color_success' : 'slds-media slds-text-color_error';
//     }

//     get testResultIcon() {
//         if (!this.testResults) return '';
//         return this.testResults.startsWith('SUCCESS') ? 'utility:success' : 'utility:error';
//     }

//     showToast(title, message, variant) {
//         this.dispatchEvent(new ShowToastEvent({
//             title: title,
//             message: message,
//             variant: variant
//         }));
//     }
// }
