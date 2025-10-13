// import { LightningElement, track, wire } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import generateClause from '@salesforce/apex/ClauseGenerator.generateClause';
// import validateCompliance from '@salesforce/apex/ComplianceChecker.validateClause';
// import getDetailedComplianceAnalysis from '@salesforce/apex/ComplianceChecker.getDetailedComplianceAnalysis';
// import createDocumentRequest from '@salesforce/apex/DocumentGenerationController.createDocumentRequest';
// import generateDocumentWithAI from '@salesforce/apex/DocumentGenerationController.generateDocumentWithAI';
// import getDocumentTemplates from '@salesforce/apex/DocumentGenerationController.getDocumentTemplates';

// export default class DocumentGenerator extends LightningElement {
//     // Step Management
//     @track currentStep = '1';
    
//     // Form Data
//     @track selectedContractType = '';
//     @track selectedRegion = '';
//     @track selectedRole = '';
//     @track selectedOutputFormat = 'PDF';
//     @track selectedTemplate = '';
//     @track additionalClauses = '';
    
//     // AI Enhancement Options
//     @track selectedTone = 'professional';
//     @track selectedLength = 'standard';
//     @track aiProcessingEnabled = true;
    
//     // Generated Content
//     @track generatedClause = '';
//     @track complianceScore = 0;
//     @track complianceStatusLabel = '';
//     @track riskLevel = '';
//     @track recommendations = [];
    
//     // UI State
//     @track isGeneratingPreview = false;
//     @track isGeneratingDocument = false;
//     @track previewGenerated = false;
//     @track finalDocumentGenerated = false;
//     @track hasError = false;
//     @track errorMessage = '';
//     @track templateOptions = [];

//     // Dropdown Options
//     contractTypeOptions = [
//         { label: 'Employment Contract', value: 'Employment' },
//         { label: 'Non-Disclosure Agreement', value: 'NDA' },
//         { label: 'Service Level Agreement', value: 'SLA' },
//         { label: 'Service Agreement', value: 'Service' }
//     ];

//     regionOptions = [
//         { label: 'United States', value: 'US' },
//         { label: 'European Union', value: 'EU' },
//         { label: 'Asia Pacific', value: 'APAC' },
//         { label: 'Global', value: 'Global' }
//     ];

//     roleOptions = [
//         { label: 'Manager', value: 'Manager' },
//         { label: 'Employee', value: 'Employee' },
//         { label: 'Developer', value: 'Developer' },
//         { label: 'Administrator', value: 'Admin' }
//     ];

//     outputFormatOptions = [
//         { label: 'PDF Document', value: 'PDF' },
//         { label: 'Word Document', value: 'DOCX' },
//         { label: 'HTML Page', value: 'HTML' }
//     ];

//     toneOptions = [
//         { label: 'Professional', value: 'professional' },
//         { label: 'Formal', value: 'formal' },
//         { label: 'Friendly', value: 'friendly' },
//         { label: 'Legal', value: 'legal' }
//     ];

//     lengthOptions = [
//         { label: 'Concise', value: 'concise' },
//         { label: 'Standard', value: 'standard' },
//         { label: 'Detailed', value: 'detailed' },
//         { label: 'Comprehensive', value: 'comprehensive' }
//     ];

//     // Computed Properties
//     get isStep1() { 
//         return this.currentStep === '1'; 
//     }
    
//     get isStep2() { 
//         return this.currentStep === '2'; 
//     }
    
//     get isStep3() { 
//         return this.currentStep === '3'; 
//     }
    
//     get isStep4() { 
//         return this.currentStep === '4'; 
//     }

//     get isPreviousDisabled() {
//         return this.currentStep === '1';
//     }

//     get isNextDisabled() {
//         if (this.currentStep === '1') {
//             return !this.selectedContractType || !this.selectedRegion || !this.selectedRole;
//         } else if (this.currentStep === '2') {
//             return !this.selectedOutputFormat;
//         } else if (this.currentStep === '3') {
//             return false; // Always allow proceeding from step 3
//         } else if (this.currentStep === '4') {
//             return true; // No next button on final step
//         }
//         return false;
//     }

//     get nextButtonLabel() {
//         return this.currentStep === '4' ? 'Generate' : 'Next';
//     }

//     get showContractTypeDescription() {
//         return this.selectedContractType !== '';
//     }

//     // Based on the comprehensive analysis of all the DocGen implementation materials, I can continue the contractTypeDescription() function from where it left off. The function is designed to provide user-friendly descriptions for different contract types within the document generation system.
//     get contractTypeDescription() {
//         const descriptions = {
//             'Employment': 'Employment contracts define the terms and conditions of employment, including compensation, benefits, confidentiality obligations, and termination procedures. Used for full-time, part-time, and contract workers.',
//             'NDA': 'Non-Disclosure Agreements establish confidentiality obligations and non-disclosure terms to protect sensitive business information, trade secrets, and proprietary data shared between parties.',
//             'SLA': 'Service Level Agreements define service level commitments, performance metrics, availability requirements, and remedies for service failures between service providers and clients.',
//             'Service': 'Service Agreements outline the terms for professional services, deliverables, payment schedules, intellectual property rights, and performance expectations between service providers and clients.'
//         };
        
//         return descriptions[this.selectedContractType] || 'Select a contract type to view its description.';
//     }

//     get complianceStatusClass() {
//         if (this.complianceScore >= 80) {
//             return 'slds-theme_success';
//         } else if (this.complianceScore >= 60) {
//             return 'slds-theme_warning';
//         } else {
//             return 'slds-theme_error';
//         }
//     }

//     get hasRecommendations() {
//         return this.recommendations && this.recommendations.length > 0;
//     }

//     // Event Handlers
//     handleContractTypeChange(event) {
//         this.selectedContractType = event.detail.value;
//         this.loadTemplatesForContractType();
//         this.clearError();
//     }

//     handleRegionChange(event) {
//         this.selectedRegion = event.detail.value;
//         this.loadTemplatesForContractType();
//         this.clearError();
//     }

//     handleRoleChange(event) {
//         this.selectedRole = event.detail.value;
//         this.clearError();
//     }

//     handleOutputFormatChange(event) {
//         this.selectedOutputFormat = event.detail.value;
//     }

//     handleTemplateChange(event) {
//         this.selectedTemplate = event.detail.value;
//     }

//     handleAdditionalClausesChange(event) {
//         this.additionalClauses = event.detail.value;
//     }

//     handleToneChange(event) {
//         this.selectedTone = event.detail.value;
//     }

//     handleLengthChange(event) {
//         this.selectedLength = event.detail.value;
//     }

//     handleAIProcessingChange(event) {
//         this.aiProcessingEnabled = event.detail.checked;
//     }

//     // Navigation Methods
//     handleNext() {
//         if (this.currentStep === '1') {
//             this.currentStep = '2';
//         } else if (this.currentStep === '2') {
//             this.currentStep = '3';
//         } else if (this.currentStep === '3') {
//             this.currentStep = '4';
//         }
//     }

//     handlePrevious() {
//         if (this.currentStep === '2') {
//             this.currentStep = '1';
//         } else if (this.currentStep === '3') {
//             this.currentStep = '2';
//         } else if (this.currentStep === '4') {
//             this.currentStep = '3';
//         }
//     }

//     // Document Generation Methods
//     async handleGeneratePreview() {
//         this.isGeneratingPreview = true;
//         this.clearError();
        
//         try {
//             const aiParameters = {
//                 tone: this.selectedTone,
//                 length: this.selectedLength,
//                 aiProcessing: this.aiProcessingEnabled
//             };
            
//             const result = await generateDocumentWithAI({
//                 region: this.selectedRegion,
//                 role: this.selectedRole,
//                 contractType: this.selectedContractType,
//                 aiParameters: aiParameters
//             });
            
//             this.generatedClause = result.generatedClause;
//             this.processComplianceAnalysis(result.complianceAnalysis);
//             this.previewGenerated = true;
            
//             this.showToast('Success', 'Document preview generated successfully', 'success');
            
//         } catch (error) {
//             this.handleError('Failed to generate preview: ' + error.body.message);
//         } finally {
//             this.isGeneratingPreview = false;
//         }
//     }

//     async handleGenerateFinalDocument() {
//         this.isGeneratingDocument = true;
//         this.clearError();
        
//         try {
//             const requestId = await createDocumentRequest({
//                 documentType: this.selectedContractType,
//                 region: this.selectedRegion,
//                 role: this.selectedRole,
//                 templateId: this.selectedTemplate,
//                 additionalClauses: this.additionalClauses
//             });
            
//             // Get detailed compliance analysis for final document
//             const complianceAnalysis = await getDetailedComplianceAnalysis({
//                 clauseText: this.generatedClause,
//                 region: this.selectedRegion,
//                 contractType: this.selectedContractType
//             });
            
//             this.processComplianceAnalysis(complianceAnalysis);
//             this.finalDocumentGenerated = true;
            
//             this.showToast('Success', `Document generated successfully. Request ID: ${requestId}`, 'success');
            
//         } catch (error) {
//             this.handleError('Failed to generate final document: ' + error.body.message);
//         } finally {
//             this.isGeneratingDocument = false;
//         }
//     }

//     async loadTemplatesForContractType() {
//         if (this.selectedRegion && this.selectedContractType) {
//             try {
//                 const templates = await getDocumentTemplates({
//                     region: this.selectedRegion,
//                     contractType: this.selectedContractType
//                 });
                
//                 this.templateOptions = templates.map(template => ({
//                     label: template.name,
//                     value: template.id
//                 }));
                
//                 // Add default option
//                 this.templateOptions.unshift({
//                     label: 'Default Template',
//                     value: ''
//                 });
                
//             } catch (error) {
//                 console.error('Failed to load templates:', error);
//                 this.templateOptions = [{ label: 'Default Template', value: '' }];
//             }
//         }
//     }

//     processComplianceAnalysis(analysis) {
//         this.complianceScore = analysis.complianceScore || 0;
//         this.complianceStatusLabel = analysis.isCompliant ? 'Compliant' : 'Non-Compliant';
//         this.riskLevel = analysis.riskLevel || 'Unknown';
//         this.recommendations = analysis.recommendations || [];
//     }

//     // Action Methods
//     handleDownloadDocument() {
//         // Implementation for document download
//         this.showToast('Info', 'Document download functionality will be implemented', 'info');
//     }

//     handleSaveDraft() {
//         // Implementation for saving draft
//         this.showToast('Info', 'Save draft functionality will be implemented', 'info');
//     }

//     handleGenerateNew() {
//         // Reset all form data
//         this.currentStep = '1';
//         this.selectedContractType = '';
//         this.selectedRegion = '';
//         this.selectedRole = '';
//         this.selectedOutputFormat = 'PDF';
//         this.selectedTemplate = '';
//         this.additionalClauses = '';
//         this.selectedTone = 'professional';
//         this.selectedLength = 'standard';
//         this.aiProcessingEnabled = true;
//         this.generatedClause = '';
//         this.complianceScore = 0;
//         this.complianceStatusLabel = '';
//         this.riskLevel = '';
//         this.recommendations = [];
//         this.previewGenerated = false;
//         this.finalDocumentGenerated = false;
//         this.clearError();
        
//         this.showToast('Success', 'Form reset. Ready to generate new document', 'success');
//     }

//     // Utility Methods
//     handleError(message) {
//         this.hasError = true;
//         this.errorMessage = message;
//         this.showToast('Error', message, 'error');
//     }

//     clearError() {
//         this.hasError = false;
//         this.errorMessage = '';
//     }

//     showToast(title, message, variant) {
//         const event = new ShowToastEvent({
//             title: title,
//             message: message,
//             variant: variant
//         });
//         this.dispatchEvent(event);
//     }
// }

// import { LightningElement, track, wire } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import generateClause from '@salesforce/apex/ClauseGenerator.generateClause';
// import validateCompliance from '@salesforce/apex/ComplianceChecker.validateClause';
// import getDetailedComplianceAnalysis from '@salesforce/apex/ComplianceChecker.getDetailedComplianceAnalysis';
// import createDocumentRequest from '@salesforce/apex/DocumentGenerationController.createDocumentRequest';
// import generateDocumentWithAI from '@salesforce/apex/DocumentGenerationController.generateDocumentWithAI';
// import getDocumentTemplates from '@salesforce/apex/DocumentGenerationController.getDocumentTemplates';

// export default class DocumentGenerator extends LightningElement {
//     // Step Management
//     @track currentStep = '1';
    
//     // Form Data
//     @track selectedContractType = '';
//     @track selectedRegion = '';
//     @track selectedRole = '';
//     @track selectedOutputFormat = 'PDF';
//     @track selectedTemplate = '';
//     @track additionalClauses = '';
    
//     // AI Enhancement Options
//     @track selectedTone = 'professional';
//     @track selectedLength = 'standard';
//     @track aiProcessingEnabled = true;
    
//     // Generated Content
//     @track generatedClause = '';
//     @track complianceScore = 0;
//     @track complianceStatusLabel = '';
//     @track riskLevel = '';
//     @track recommendations = [];
    
//     // UI State
//     @track isGeneratingPreview = false;
//     @track isGeneratingDocument = false;
//     @track previewGenerated = false;
//     @track finalDocumentGenerated = false;
//     @track hasError = false;
//     @track errorMessage = '';
//     @track templateOptions = [];

//     // Dropdown Options
//     contractTypeOptions = [
//         { label: 'Employment Contract', value: 'Employment' },
//         { label: 'Non-Disclosure Agreement', value: 'NDA' },
//         { label: 'Service Level Agreement', value: 'SLA' },
//         { label: 'Service Agreement', value: 'Service' }
//     ];

//     regionOptions = [
//         { label: 'United States', value: 'US' },
//         { label: 'European Union', value: 'EU' },
//         { label: 'Asia Pacific', value: 'APAC' },
//         { label: 'Global', value: 'Global' }
//     ];

//     roleOptions = [
//         { label: 'Manager', value: 'Manager' },
//         { label: 'Employee', value: 'Employee' },
//         { label: 'Developer', value: 'Developer' },
//         { label: 'Administrator', value: 'Admin' }
//     ];

//     outputFormatOptions = [
//         { label: 'PDF Document', value: 'PDF' },
//         { label: 'Word Document', value: 'DOCX' },
//         { label: 'HTML Page', value: 'HTML' }
//     ];

//     toneOptions = [
//         { label: 'Professional', value: 'professional' },
//         { label: 'Formal', value: 'formal' },
//         { label: 'Friendly', value: 'friendly' },
//         { label: 'Legal', value: 'legal' }
//     ];

//     lengthOptions = [
//         { label: 'Concise', value: 'concise' },
//         { label: 'Standard', value: 'standard' },
//         { label: 'Detailed', value: 'detailed' },
//         { label: 'Comprehensive', value: 'comprehensive' }
//     ];

//     // Computed Properties
//     get isStep1() { return this.currentStep === '1'; }
//     get isStep2() { return this.currentStep === '2'; }
//     get isStep3() { return this.currentStep === '3'; }
//     get isStep4() { return this.currentStep === '4'; }

//     get isPreviousDisabled() {
//         return this.currentStep === '1';
//     }

//     get isNextDisabled() {
//         if (this.currentStep === '1') {
//             return !this.selectedContractType || !this.selectedRegion || !this.selectedRole;
//         } else if (this.currentStep === '2') {
//             return !this.selectedOutputFormat;
//         } else if (this.currentStep === '3') {
//             return false; // Always allow proceeding from step 3
//         } else if (this.currentStep === '4') {
//             return true; // No next button on final step
//         }
//         return false;
//     }

//     get nextButtonLabel() {
//         return this.currentStep === '4' ? 'Generate' : 'Next';
//     }

//     get showContractTypeDescription() {
//         return this.selectedContractType !== '';
//     }
// //Based on the comprehensive analysis of all the DocGen implementation materials, I can continue the contractTypeDescription() function from where it left off. The function is designed to provide user-friendly descriptions for different contract types within the document generation system.
// get contractTypeDescription() {
//     const descriptions = {
//         'Employment': 'Employment contracts define the terms and conditions of employment, including compensation, benefits, confidentiality obligations, and termination procedures. Used for full-time, part-time, and contract workers.',
//         'NDA': 'Non-Disclosure Agreements establish confidentiality obligations and non-disclosure terms to protect sensitive business information, trade secrets, and proprietary data shared between parties.',
//         'SLA': 'Service Level Agreements define service level commitments, performance metrics, availability requirements, and remedies for service failures between service providers and clients.',
//         'Service': 'Service Agreements outline the terms for professional services, deliverables, payment schedules, intellectual property rights, and performance expectations between service providers and clients.'
//     };
    
//     return descriptions[this.selectedContractType] || 'Select a contract type to view its description.';
// }

// get complianceStatusClass() {
//     if (this.complianceScore >= 80) {
//         return 'slds-theme_success';
//     } else if (this.complianceScore >= 60) {
//         return 'slds-theme_warning';
//     } else {
//         return 'slds-theme_error';
//     }
// }

// get hasRecommendations() {
//     return this.recommendations && this.recommendations.length > 0;
// }

// // Event Handlers
// handleContractTypeChange(event) {
//     this.selectedContractType = event.detail.value;
//     this.loadTemplatesForContractType();
//     this.clearError();
// }

// handleRegionChange(event) {
//     this.selectedRegion = event.detail.value;
//     this.loadTemplatesForContractType();
//     this.clearError();
// }

// handleRoleChange(event) {
//     this.selectedRole = event.detail.value;
//     this.clearError();
// }

// handleOutputFormatChange(event) {
//     this.selectedOutputFormat = event.detail.value;
// }

// handleTemplateChange(event) {
//     this.selectedTemplate = event.detail.value;
// }

// handleAdditionalClausesChange(event) {
//     this.additionalClauses = event.detail.value;
// }

// handleToneChange(event) {
//     this.selectedTone = event.detail.value;
// }

// handleLengthChange(event) {
//     this.selectedLength = event.detail.value;
// }

// handleAIProcessingChange(event) {
//     this.aiProcessingEnabled = event.detail.checked;
// }

// // Navigation Methods
// handleNext() {
//     if (this.currentStep === '1') {
//         this.currentStep = '2';
//     } else if (this.currentStep === '2') {
//         this.currentStep = '3';
//     } else if (this.currentStep === '3') {
//         this.currentStep = '4';
//     }
// }

// handlePrevious() {
//     if (this.currentStep === '2') {
//         this.currentStep = '1';
//     } else if (this.currentStep === '3') {
//         this.currentStep = '2';
//     } else if (this.currentStep === '4') {
//         this.currentStep = '3';
//     }
// }

// // Document Generation Methods
// async handleGeneratePreview() {
//     this.isGeneratingPreview = true;
//     this.clearError();
    
//     try {
//         const aiParameters = {
//             tone: this.selectedTone,
//             length: this.selectedLength,
//             aiProcessing: this.aiProcessingEnabled
//         };
        
//         const result = await generateDocumentWithAI({
//             region: this.selectedRegion,
//             role: this.selectedRole,
//             contractType: this.selectedContractType,
//             aiParameters: aiParameters
//         });
        
//         this.generatedClause = result.generatedClause;
//         this.processComplianceAnalysis(result.complianceAnalysis);
//         this.previewGenerated = true;
        
//         this.showToast('Success', 'Document preview generated successfully', 'success');
        
//     } catch (error) {
//         this.handleError('Failed to generate preview: ' + error.body.message);
//     } finally {
//         this.isGeneratingPreview = false;
//     }
// }

// async handleGenerateFinalDocument() {
//     this.isGeneratingDocument = true;
//     this.clearError();
    
//     try {
//         const requestId = await createDocumentRequest({
//             documentType: this.selectedContractType,
//             region: this.selectedRegion,
//             role: this.selectedRole,
//             templateId: this.selectedTemplate,
//             additionalClauses: this.additionalClauses
//         });
        
//         // Get detailed compliance analysis for final document
//         const complianceAnalysis = await getDetailedComplianceAnalysis({
//             clauseText: this.generatedClause,
//             region: this.selectedRegion,
//             contractType: this.selectedContractType
//         });
        
//         this.processComplianceAnalysis(complianceAnalysis);
//         this.finalDocumentGenerated = true;
        
//         this.showToast('Success', `Document generated successfully. Request ID: ${requestId}`, 'success');
        
//     } catch (error) {
//         this.handleError('Failed to generate final document: ' + error.body.message);
//     } finally {
//         this.isGeneratingDocument = false;
//     }
// }

// async loadTemplatesForContractType() {
//     if (this.selectedRegion && this.selectedContractType) {
//         try {
//             const templates = await getDocumentTemplates({
//                 region: this.selectedRegion,
//                 contractType: this.selectedContractType
//             });
            
//             this.templateOptions = templates.map(template => ({
//                 label: template.name,
//                 value: template.id
//             }));
            
//             // Add default option
//             this.templateOptions.unshift({
//                 label: 'Default Template',
//                 value: ''
//             });
            
//         } catch (error) {
//             console.error('Failed to load templates:', error);
//             this.templateOptions = [{ label: 'Default Template', value: '' }];
//         }
//     }
// }

// processComplianceAnalysis(analysis) {
//     this.complianceScore = analysis.complianceScore || 0;
//     this.complianceStatusLabel = analysis.isCompliant ? 'Compliant' : 'Non-Compliant';
//     this.riskLevel = analysis.riskLevel || 'Unknown';
//     this.recommendations = analysis.recommendations || [];
// }

// // Action Methods
// handleDownloadDocument() {
//     // Implementation for document download
//     this.showToast('Info', 'Document download functionality will be implemented', 'info');
// }

// handleSaveDraft() {
//     // Implementation for saving draft
//     this.showToast('Info', 'Save draft functionality will be implemented', 'info');
// }

// handleGenerateNew() {
//     // Reset all form data
//     this.currentStep = '1';
//     this.selectedContractType = '';
//     this.selectedRegion = '';
//     this.selectedRole = '';
//     this.selectedOutputFormat = 'PDF';
//     this.selectedTemplate = '';
//     this.additionalClauses = '';
//     this.selectedTone = 'professional';
//     this.selectedLength = 'standard';
//     this.aiProcessingEnabled = true;
//     this.generatedClause = '';
//     this.complianceScore = 0;
//     this.complianceStatusLabel = '';
//     this.riskLevel = '';
//     this.recommendations = [];
//     this.previewGenerated = false;
//     this.finalDocumentGenerated = false;
//     this.clearError();
    
//     this.showToast('Success', 'Form reset. Ready to generate new document', 'success');
// }

// // Utility Methods
// handleError(message) {
//     this.hasError = true;
//     this.errorMessage = message;
//     this.showToast('Error', message, 'error');
// }

// clearError() {
//     this.hasError = false;
//     this.errorMessage = '';
// }

// showToast(title, message, variant) {
//     const event = new ShowToastEvent({
//         title: title,
//         message: message,
//         variant: variant
//     });
//     this.dispatchEvent(event);
// }
// }

// import { LightningElement, track } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import { NavigationMixin } from 'lightning/navigation';
// import createDocumentRequest from '@salesforce/apex/DocumentGenerationController.createDocumentRequest';
// import generateAndRequestSignature from '@salesforce/apex/DocumentGenerationController.generateAndRequestSignature';

// export default class DocumentGenerator extends NavigationMixin(LightningElement) {
//     /* -----------------------------
//        Step Management
//     ------------------------------ */
//     @track currentStep = 1;
//     @track totalSteps = 4;

//     /* -----------------------------
//        Form Data
//     ------------------------------ */
//     @track selectedRegion = '';
//     @track selectedRole = '';
//     @track selectedContractType = '';
//     @track additionalRequirements = '';
//     @track aiProcessingEnabled = true;
//     @track signerEmail = '';
//     @track signerName = '';
//     @track signatureInstructions = '';
//     @track selectedSignatureOptions = [];

//     /* -----------------------------
//        Generation State
//     ------------------------------ */
//     @track isGenerating = false;
//     @track generatedClause = '';
//     @track documentId = '';
//     @track signatureRequestId = '';
//     @track complianceStatus = null;
//     @track complianceDetails = null;

//     /* -----------------------------
//        Error Handling
//     ------------------------------ */
//     @track showError = false;
//     @track errorMessage = '';

//     /* -----------------------------
//        Email Status
//     ------------------------------ */
//     @track emailSentStatus = false;

//     /* -----------------------------
//        Options Data
//     ------------------------------ */
//     regionOptions = [
//         { label: 'United States', value: 'US' },
//         { label: 'European Union', value: 'EU' },
//         { label: 'Asia Pacific', value: 'APAC' },
//         { label: 'Global', value: 'GLOBAL' }
//     ];

//     roleOptions = [
//         { label: 'Manager', value: 'Manager' },
//         { label: 'Employee', value: 'Employee' },
//         { label: 'Developer', value: 'Developer' },
//         { label: 'Admin', value: 'Admin' },
//         { label: 'Contractor', value: 'Contractor' },
//         { label: 'Intern', value: 'Intern' }
//     ];

//     contractTypeOptions = [
//         { label: 'Employment Agreement', value: 'Employment' },
//         { label: 'Non-Disclosure Agreement', value: 'NDA' },
//         { label: 'Service Level Agreement', value: 'SLA' },
//         { label: 'Contractor Agreement', value: 'Contractor' },
//         { label: 'Consulting Agreement', value: 'Consulting' }
//     ];

//     signatureOptionsList = [
//         { label: 'Require Identity Verification', value: 'identity_verification' },
//         { label: 'Send Reminder Emails', value: 'email_reminders' },
//         { label: 'Allow Signature Delegation', value: 'signature_delegation' },
//         { label: 'Enable Mobile Signing', value: 'mobile_signing' }
//     ];

//     /* -----------------------------
//        Computed Properties
//     ------------------------------ */
//     get isStep1() { return this.currentStep === 1; }
//     get isStep2() { return this.currentStep === 2; }
//     get isStep3() { return this.currentStep === 3; }
//     get isStep4() { return this.currentStep === 4; }

//     get isFirstStep() { return this.currentStep === 1; }
//     get isLastStep() { return this.currentStep === this.totalSteps; }
//     get currentStepNumber() { return this.currentStep; }

//     get progressText() {
//         switch (this.currentStep) {
//             case 1: return 'Configuration';
//             case 2: return 'Generation';
//             case 3: return 'Signature';
//             case 4: return 'Complete';
//             default: return 'Processing';
//         }
//     }

//     get progressStyle() {
//         const percentage = (this.currentStep / this.totalSteps) * 100;
//         return `width: ${percentage}%`;
//     }

//     get nextButtonLabel() {
//         switch (this.currentStep) {
//             case 1: return 'Configure';
//             case 2: return 'Generate';
//             case 3: return 'Request Signature';
//             case 4: return 'Finish';
//             default: return 'Next';
//         }
//     }

//     get isNextDisabled() {
//         switch (this.currentStep) {
//             case 1:
//                 return !this.selectedRegion || !this.selectedRole || !this.selectedContractType;
//             case 2:
//                 return !this.generatedClause || this.isGenerating;
//             case 3:
//                 return !this.signerEmail || !this.signerName;
//             case 4:
//                 return false;
//             default:
//                 return false;
//         }
//     }

//     get complianceStatusClass() {
//         if (!this.complianceStatus) return '';
//         return this.complianceStatus.isCompliant
//             ? 'slds-box slds-theme_success slds-text-align_center slds-p-around_small'
//             : 'slds-box slds-theme_warning slds-text-align_center slds-p-around_small';
//     }

//     get complianceIcon() {
//         if (!this.complianceStatus) return 'utility:info';
//         return this.complianceStatus.isCompliant ? 'utility:success' : 'utility:warning';
//     }

//     get complianceVariant() {
//         if (!this.complianceStatus) return 'neutral';
//         return this.complianceStatus.isCompliant ? 'success' : 'warning';
//     }

//     get complianceStatusText() {
//         if (!this.complianceStatus) return 'Compliance check pending';
//         return this.complianceStatus.isCompliant
//             ? 'Document is compliant with all regulations'
//             : 'Document requires compliance review';
//     }

//     get complianceScore() {
//         return this.complianceDetails?.complianceScore
//             ? `${this.complianceDetails.complianceScore}%`
//             : 'N/A';
//     }

//     get complianceAnalysis() {
//         return this.complianceDetails?.analysis || 'No detailed analysis available';
//     }

//     get complianceViolations() {
//         return this.complianceDetails?.violations || [];
//     }

//     /* -----------------------------
//        Event Handlers - Step 1
//     ------------------------------ */
//     handleRegionChange(event) {
//         this.selectedRegion = event.detail.value;
//         this.resetGenerationData();
//     }

//     handleRoleChange(event) {
//         this.selectedRole = event.detail.value;
//         this.resetGenerationData();
//     }

//     handleContractTypeChange(event) {
//         this.selectedContractType = event.detail.value;
//         this.resetGenerationData();
//     }

//     handleAdditionalRequirementsChange(event) {
//         this.additionalRequirements = event.detail.value;
//     }

//     handleAIProcessingChange(event) {
//         this.aiProcessingEnabled = event.detail.checked;
//     }

//     /* -----------------------------
//        Event Handlers - Step 3
//     ------------------------------ */
//     handleSignerEmailChange(event) {
//         this.signerEmail = event.detail.value;
//     }

//     handleSignerNameChange(event) {
//         this.signerName = event.detail.value;
//     }

//     handleSignatureInstructionsChange(event) {
//         this.signatureInstructions = event.detail.value;
//     }

//     handleSignatureOptionsChange(event) {
//         this.selectedSignatureOptions = event.detail.value;
//     }

//     /* -----------------------------
//        Navigation Handlers
//     ------------------------------ */
//     handleNext() {
//         if (this.currentStep < this.totalSteps) {
//             if (this.currentStep === 2 && !this.generatedClause) {
//                 this.handleGenerateDocument();
//             } else if (this.currentStep === 3) {
//                 this.handleRequestSignature();
//             } else {
//                 this.currentStep++;
//             }
//         }
//     }

//     handlePrevious() {
//         if (this.currentStep > 1) {
//             this.currentStep--;
//         }
//     }

//     /* -----------------------------
//        Document Generation
//     ------------------------------ */
//     async handleGenerateDocument() {
//         this.isGenerating = true;
//         this.clearError();

//         try {
//             this.documentId = await createDocumentRequest({
//                 contractType: this.selectedContractType,
//                 region: this.selectedRegion,
//                 role: this.selectedRole,
//                 templateId: null,
//                 additionalRequirements: this.additionalRequirements
//             });

//             await this.delay(2000); // UX delay
//             this.generatedClause = await this.getGeneratedClause();
//             this.complianceStatus = await this.validateCompliance();

//             this.currentStep = 3;
//             this.showSuccessToast('Document generated successfully!');
//         } catch (error) {
//             this.handleError(error);
//         } finally {
//             this.isGenerating = false;
//         }
//     }

//     /* -----------------------------
//        Signature Request
//     ------------------------------ */
//     async handleRequestSignature() {
//         try {
//             const result = await generateAndRequestSignature({
//                 configId: this.documentId,
//                 signerEmail: this.signerEmail,
//                 signerName: this.signerName
//             });

//             this.signatureRequestId = result.signatureRequestId;
//             this.emailSentStatus = true;
//             this.currentStep = 4;

//             this.showSuccessToast('Signature request sent successfully!');
//         } catch (error) {
//             this.handleError(error);
//         }
//     }

//     /* -----------------------------
//        Action Handlers
//     ------------------------------ */
//     handleDownloadDocument() {
//         const element = document.createElement('a');
//         const file = new Blob([this.generateDocumentContent()], { type: 'text/plain' });

//         element.href = URL.createObjectURL(file);
//         element.download = `${this.selectedContractType}_${new Date().toISOString().split('T')[0]}.txt`;

//         document.body.appendChild(element);
//         element.click();
//         document.body.removeChild(element);

//         this.showSuccessToast('Document downloaded successfully!');
//     }

//     handleViewDocument() {
//         this[NavigationMixin.Navigate]({
//             type: 'standard__recordPage',
//             attributes: {
//                 recordId: this.documentId,
//                 objectApiName: 'DocumentLifecycleConfiguration__c',
//                 actionName: 'view'
//             }
//         });
//     }

//     handleGenerateNew() {
//         this.resetComponent();
//         this.showSuccessToast('Ready for new document generation!');
//     }

//     /* -----------------------------
//        Error Handling
//     ------------------------------ */
//     handleError(error) {
//         console.error('Error:', error);
//         this.errorMessage = error.body ? error.body.message : error.message || 'An unexpected error occurred';
//         this.showError = true;
//         this.showErrorToast(this.errorMessage);
//     }

//     handleCloseError() {
//         this.showError = false;
//         this.errorMessage = '';
//     }

//     clearError() {
//         this.showError = false;
//         this.errorMessage = '';
//     }

//     /* -----------------------------
//        Helpers (Document Content)
//     ------------------------------ */
//     async getGeneratedClause() {
//         const templates = {
//             Employment: `EMPLOYMENT AGREEMENT
// This Employment Agreement is entered into between the Company and ${this.signerName || '[Employee Name]'}, effective as of the date of execution.

// TERMS AND CONDITIONS:
// 1. Position and Responsibilities: The Employee will serve in the capacity of ${this.selectedRole} and will perform duties as assigned by the Company.
// 2. Compensation: The Employee will receive compensation as detailed in the attached compensation schedule.
// 3. Employment Period: Commences on the effective date until terminated as per provisions.
// 4. Confidentiality: The Employee agrees to maintain confidentiality.
// 5. Compliance: Governed by ${
//                 this.selectedRegion === 'US'
//                     ? 'United States federal and state laws'
//                     : this.selectedRegion === 'EU'
//                         ? 'European Union employment regulations and GDPR'
//                         : 'applicable local employment laws'
//             }.`,

//             NDA: `NON-DISCLOSURE AGREEMENT
// This NDA is entered into between the Company and ${this.signerName || '[Party Name]'} for protecting confidential information.`,

//             SLA: `SERVICE LEVEL AGREEMENT
// This SLA is entered into between the Company and ${this.signerName || '[Service Provider]'} to define service expectations.`,

//             Contractor: `CONTRACTOR AGREEMENT
// This Agreement is entered into between the Company and ${this.signerName || '[Contractor Name]'} for provision of services.`,

//             Consulting: `CONSULTING AGREEMENT
// This Agreement is entered into between the Company and ${this.signerName || '[Consultant Name]'} for consulting services.`
//         };

//         let baseClause = templates[this.selectedContractType] || templates.Employment;

//         if (this.additionalRequirements) {
//             baseClause += `\n\nADDITIONAL REQUIREMENTS:\n${this.additionalRequirements}`;
//         }

//         if (this.aiProcessingEnabled) {
//             baseClause += this.getAIEnhancedClauses();
//         }

//         return baseClause;
//     }

//     getAIEnhancedClauses() {
//         const aiClauses = {
//             Employment: {
//                 Manager: `\n\nMANAGEMENT RESPONSIBILITIES:
// - Authorized signatory privileges
// - Team leadership duties
// - Budget oversight`,
//                 Employee: `\n\nEMPLOYEE OBLIGATIONS:
// - Adherence to policies
// - Training participation
// - Teamwork and communication`,
//                 Developer: `\n\nTECHNICAL RESPONSIBILITIES:
// - Code quality standards
// - IP assignment
// - Security compliance`,
//                 Contractor: `\n\nCONTRACTOR PROVISIONS:
// - Independent contractor status
// - Deliverable requirements
// - Liability clauses`
//             },
//             NDA: {
//                 Manager: `\n\nMANAGEMENT NDA TERMS:
// - Executive-level confidentiality`,
//                 Employee: `\n\nEMPLOYEE NDA TERMS:
// - Standard non-disclosure
// - Return of materials upon termination`
//             }
//         };

//         const roleSpecific = aiClauses[this.selectedContractType]?.[this.selectedRole] || '';
//         const regionSpecific = this.getRegionSpecificClauses();
//         return roleSpecific + regionSpecific;
//     }

//     getRegionSpecificClauses() {
//         const regionClauses = {
//             US: `\n\nUS COMPLIANCE PROVISIONS:
// - At-will employment
// - EEO compliance
// - ADA adherence`,
//             EU: `\n\nEU COMPLIANCE PROVISIONS:
// - GDPR requirements
// - Working Time Directive
// - Data transfer provisions`,
//             APAC: `\n\nAPAC COMPLIANCE PROVISIONS:
// - Local labor laws
// - Diversity provisions`,
//             GLOBAL: `\n\nGLOBAL COMPLIANCE PROVISIONS:
// - Multi-jurisdictional adherence
// - International data transfer
// - Global HR policy`
//         };

//         return regionClauses[this.selectedRegion] || '';
//     }

//     async validateCompliance() {
//         const complianceRules = {
//             Employment: {
//                 US: { requiredTerms: ['at-will', 'equal opportunity', 'confidentiality'], score: 95 },
//                 EU: { requiredTerms: ['GDPR', 'working time', 'data protection'], score: 92 }
//             },
//             NDA: {
//                 US: { requiredTerms: ['confidentiality', 'return of materials'], score: 98 },
//                 EU: { requiredTerms: ['GDPR', 'data protection'], score: 96 }
//             }
//         };

//         const rules = complianceRules[this.selectedContractType]?.[this.selectedRegion];
//         if (!rules) {
//             return {
//                 isCompliant: true,
//                 score: 85,
//                 analysis: 'Basic compliance validation completed',
//                 violations: []
//             };
//         }

//         const clauseText = this.generatedClause.toLowerCase();
//         const missingTerms = rules.requiredTerms.filter(term => !clauseText.includes(term.toLowerCase()));
//         const isCompliant = missingTerms.length === 0;

//         this.complianceDetails = {
//             complianceScore: rules.score - (missingTerms.length * 10),
//             analysis: isCompliant
//                 ? `Document meets all ${this.selectedRegion} requirements for ${this.selectedContractType}.`
//                 : `Document requires review for ${this.selectedRegion} compliance standards.`,
//             violations: missingTerms.map(term => `Missing required term: "${term}"`)
//         };

//         return {
//             isCompliant,
//             score: this.complianceDetails.complianceScore,
//             analysis: this.complianceDetails.analysis,
//             violations: this.complianceDetails.violations
//         };
//     }

//     generateDocumentContent() {
//         return `
// GENERATED DOCUMENT
// ===================
// Document ID: ${this.documentId}
// Contract Type: ${this.selectedContractType}
// Region: ${this.selectedRegion}
// Role: ${this.selectedRole}
// Generated Date: ${new Date().toLocaleDateString()}
// AI Processing: ${this.aiProcessingEnabled ? 'Enabled' : 'Disabled'}

// DOCUMENT CONTENT:
// ==================
// ${this.generatedClause}

// SIGNATURE INFORMATION:
// =======================
// Signer Name: ${this.signerName}
// Signer Email: ${this.signerEmail}
// Signature Request ID: ${this.signatureRequestId}
// Status: ${this.signatureRequestId ? 'Pending Signature' : 'Draft'}
// ${this.signatureInstructions ? `Instructions: ${this.signatureInstructions}` : ''}

// COMPLIANCE STATUS:
// ==================
// Status: ${this.complianceStatus?.isCompliant ? 'Compliant' : 'Requires Review'}
// Score: ${this.complianceDetails?.complianceScore || 'N/A'}%
// Analysis: ${this.complianceDetails?.analysis || 'No analysis available'}
// ${this.complianceDetails?.violations?.length > 0
//                 ? `Violations: ${this.complianceDetails.violations.join(', ')}`
//                 : ''}
// `;
//     }

//     /* -----------------------------
//        Reset Handlers
//     ------------------------------ */
//     resetGenerationData() {
//         this.generatedClause = '';
//         this.complianceStatus = null;
//         this.complianceDetails = null;
//         this.documentId = '';
//         this.signatureRequestId = '';
//         this.emailSentStatus = false;
//     }

//     resetComponent() {
//         this.currentStep = 1;
//         this.selectedRegion = '';
//         this.selectedRole = '';
//         this.selectedContractType = '';
//         this.additionalRequirements = '';
//         this.aiProcessingEnabled = true;
//         this.signerEmail = '';
//         this.signerName = '';
//         this.signatureInstructions = '';
//         this.selectedSignatureOptions = [];
//         this.resetGenerationData();
//         this.clearError();
//     }

//     /* -----------------------------
//        Utility Methods
//     ------------------------------ */
//     delay(ms) {
//         return new Promise(resolve => setTimeout(resolve, ms));
//     }

//     showSuccessToast(message) {
//         this.dispatchEvent(new ShowToastEvent({
//             title: 'Success',
//             message,
//             variant: 'success'
//         }));
//     }

//     showErrorToast(message) {
//         this.dispatchEvent(new ShowToastEvent({
//             title: 'Error',
//             message,
//             variant: 'error'
//         }));
//     }
// }

import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import createDocumentRequest from '@salesforce/apex/DocumentGenerationController.createDocumentRequest';
import generateAndRequestSignature from '@salesforce/apex/DocumentGenerationController.generateAndRequestSignature';

export default class DocumentGenerator extends NavigationMixin(LightningElement) {
    // Step Management
    @track currentStep = 1;
    @track totalSteps = 4;
    
    // Form Data
    @track selectedRegion = '';
    @track selectedRole = '';
    @track selectedContractType = '';
    @track additionalRequirements = '';
    @track aiProcessingEnabled = true;
    @track signerEmail = '';
    @track signerName = '';
    @track signatureInstructions = '';
    @track selectedSignatureOptions = [];
    
    // Generation State
    @track isGenerating = false;
    @track generatedClause = '';
    @track documentId = '';
    @track signatureRequestId = '';
    @track complianceStatus = null;
    @track complianceDetails = null;
    
    // Error Handling
    @track showError = false;
    @track errorMessage = '';
    
    // Email Status
    @track emailSentStatus = false;

    // Options Data
    regionOptions = [
        { label: 'United States', value: 'US' },
        { label: 'European Union', value: 'EU' },
        { label: 'Asia Pacific', value: 'APAC' },
        { label: 'Global', value: 'GLOBAL' }
    ];

    roleOptions = [
        { label: 'Manager', value: 'Manager' },
        { label: 'Employee', value: 'Employee' },
        { label: 'Developer', value: 'Developer' },
        { label: 'Admin', value: 'Admin' },
        { label: 'Contractor', value: 'Contractor' },
        { label: 'Intern', value: 'Intern' }
    ];

    contractTypeOptions = [
        { label: 'Employment Agreement', value: 'Employment' },
        { label: 'Non-Disclosure Agreement', value: 'NDA' },
        { label: 'Service Level Agreement', value: 'SLA' },
        { label: 'Contractor Agreement', value: 'Contractor' },
        { label: 'Consulting Agreement', value: 'Consulting' }
    ];

    signatureOptionsList = [
        { label: 'Require Identity Verification', value: 'identity_verification' },
        { label: 'Send Reminder Emails', value: 'email_reminders' },
        { label: 'Allow Signature Delegation', value: 'signature_delegation' },
        { label: 'Enable Mobile Signing', value: 'mobile_signing' }
    ];

    // Computed Properties
    get isStep1() { return this.currentStep === 1; }
    get isStep2() { return this.currentStep === 2; }
    get isStep3() { return this.currentStep === 3; }
    get isStep4() { return this.currentStep === 4; }
    
    get isFirstStep() { return this.currentStep === 1; }
    get isLastStep() { return this.currentStep === this.totalSteps; }
    
    get currentStepNumber() { return this.currentStep; }
    
    get progressText() {
        switch(this.currentStep) {
            case 1: return 'Configuration';
            case 2: return 'Generation';
            case 3: return 'Signature';
            case 4: return 'Complete';
            default: return 'Processing';
        }
    }
    
    get progressStyle() {
        const percentage = (this.currentStep / this.totalSteps) * 100;
        return `width: ${percentage}%`;
    }
    
    get nextButtonLabel() {
        switch(this.currentStep) {
            case 1: return 'Configure';
            case 2: return 'Generate';
            case 3: return 'Request Signature';
            case 4: return 'Finish';
            default: return 'Next';
        }
    }
    
    get isNextDisabled() {
        switch(this.currentStep) {
            case 1:
                return !this.selectedRegion || !this.selectedRole || !this.selectedContractType;
            case 2:
                return !this.generatedClause || this.isGenerating;
            case 3:
                return !this.signerEmail || !this.signerName;
            case 4:
                return false;
            default:
                return false;
        }
    }
    
    get complianceStatusClass() {
        if (!this.complianceStatus) return '';
        return this.complianceStatus.isCompliant ? 
            'slds-box slds-theme_success slds-text-align_center slds-p-around_small' :
            'slds-box slds-theme_warning slds-text-align_center slds-p-around_small';
    }
    
    get complianceIcon() {
        if (!this.complianceStatus) return 'utility:info';
        return this.complianceStatus.isCompliant ? 'utility:success' : 'utility:warning';
    }
    
    get complianceVariant() {
        if (!this.complianceStatus) return 'neutral';
        return this.complianceStatus.isCompliant ? 'success' : 'warning';
    }
    
    get complianceStatusText() {
        if (!this.complianceStatus) return 'Compliance check pending';
        return this.complianceStatus.isCompliant ? 
            'Document is compliant with all regulations' : 
            'Document requires compliance review';
    }
    
    get complianceScore() {
        return this.complianceDetails?.complianceScore ? 
            `${this.complianceDetails.complianceScore}%` : 'N/A';
    }
    
    get complianceAnalysis() {
        return this.complianceDetails?.analysis || 'No detailed analysis available';
    }
    
    get complianceViolations() {
        return this.complianceDetails?.violations || [];
    }

    // Event Handlers - Step 1
    handleRegionChange(event) {
        this.selectedRegion = event.detail.value;
        this.resetGenerationData();
    }
    
    handleRoleChange(event) {
        this.selectedRole = event.detail.value;
        this.resetGenerationData();
    }
    
    handleContractTypeChange(event) {
        this.selectedContractType = event.detail.value;
        this.resetGenerationData();
    }
    
    handleAdditionalRequirementsChange(event) {
        this.additionalRequirements = event.detail.value;
    }
    
    handleAIProcessingChange(event) {
        this.aiProcessingEnabled = event.detail.checked;
    }

    // Event Handlers - Step 3
    handleSignerEmailChange(event) {
        this.signerEmail = event.detail.value;
    }
    
    handleSignerNameChange(event) {
        this.signerName = event.detail.value;
    }
    
    handleSignatureInstructionsChange(event) {
        this.signatureInstructions = event.detail.value;
    }
    
    handleSignatureOptionsChange(event) {
        this.selectedSignatureOptions = event.detail.value;
    }

    // Navigation Handlers
    handleNext() {
        if (this.currentStep < this.totalSteps) {
            if (this.currentStep === 2 && !this.generatedClause) {
                this.handleGenerateDocument();
            } else if (this.currentStep === 3) {
                this.handleRequestSignature();
            } else {
                this.currentStep++;
            }
        }
    }
    
    handlePrevious() {
        if (this.currentStep > 1) {
            this.currentStep--;
        }
    }

    // Document Generation Handler
    async handleGenerateDocument() {
        this.isGenerating = true;
        this.clearError();
        
        try {
            // Create document request
            this.documentId = await createDocumentRequest({
                contractType: this.selectedContractType,
                region: this.selectedRegion,
                role: this.selectedRole,
                templateId: null,
                additionalRequirements: this.additionalRequirements
            });
            
            // Simulate AI processing delay for better UX
            await this.delay(2000);
            
            // Get generated content (this would be returned by the Apex method in real implementation)
            this.generatedClause = await this.getGeneratedClause();
            
            // Validate compliance
            this.complianceStatus = await this.validateCompliance();
            
            // Move to next step automatically
            this.currentStep = 3;
            
            this.showSuccessToast('Document generated successfully!');
            
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isGenerating = false;
        }
    }

    // Signature Request Handler
    async handleRequestSignature() {
        try {
            const result = await generateAndRequestSignature({
                configId: this.documentId,
                signerEmail: this.signerEmail,
                signerName: this.signerName
            });
            
            this.signatureRequestId = result.signatureRequestId;
            this.emailSentStatus = true;
            this.currentStep = 4;
            
            this.showSuccessToast('Signature request sent successfully!');
            
        } catch (error) {
            this.handleError(error);
        }
    }

    // Action Handlers
    handleDownloadDocument() {
        // Create downloadable content
        const element = document.createElement('a');
        const file = new Blob([this.generateDocumentContent()], { type: 'text/plain' });
        element.href = URL.createObjectURL(file);
        element.download = `${this.selectedContractType}_${new Date().toISOString().split('T')[0]}.txt`;
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);
        
        this.showSuccessToast('Document downloaded successfully!');
    }
    
    handleViewDocument() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.documentId,
                objectApiName: 'DocumentLifecycleConfiguration__c',
                actionName: 'view'
            }
        });
    }
    
    handleGenerateNew() {
        // Reset all form data
        this.resetComponent();
        this.showSuccessToast('Ready for new document generation!');
    }

    // Error Handling
    handleError(error) {
        console.error('Error:', error);
        this.errorMessage = error.body ? error.body.message : error.message || 'An unexpected error occurred';
        this.showError = true;
        this.showErrorToast(this.errorMessage);
    }
    
    handleCloseError() {
        this.showError = false;
        this.errorMessage = '';
    }
    
    clearError() {
        this.showError = false;
        this.errorMessage = '';
    }

    // Helper Methods
    async getGeneratedClause() {
        // This would typically come from the Apex response
        // For now, simulating generated content
        const templates = {
            'Employment': `EMPLOYMENT AGREEMENT
            
This Employment Agreement is entered into between the Company and '[Employee Name]'}, effective as of the date of execution. TERMS AND CONDITIONS: 1. Position and Responsibilities: The Employee will serve in the capacity of ${this.selectedRole} and will perform duties as assigned by the Company. 2. Compensation: The Employee will receive compensation as detailed in the attached compensation schedule, subject to applicable deductions and withholdings. 3. Employment Period: This agreement shall commence on the effective date and continue until terminated in accordance with the provisions herein. 4. Confidentiality: The Employee agrees to maintain confidentiality of all proprietary information and trade secrets of the Company. 5. Compliance: This agreement is governed by ${this.selectedRegion === 'US' ? 'United States federal and state laws' : this.selectedRegion === 'EU' ? 'European Union employment regulations and GDPR' : 'applicable local employment laws'}.`,
            'NDA': `NON-DISCLOSURE AGREEMENT This Non-Disclosure Agreement is entered into between the Company and ${this.signerName || '[Party Name]'} for the purpose of protecting confidential information.`,
            'SLA': `SERVICE LEVEL AGREEMENT This Service Level Agreement is entered into between the Company and ${this.signerName || '[Service Provider]'} to define service expectations and performance metrics.`,
            'Contractor': `CONTRACTOR AGREEMENT This Contractor Agreement is entered into between the Company and ${this.signerName || '[Contractor Name]'} for the provision of professional services.`,
            'Consulting': `CONSULTING AGREEMENT This Consulting Agreement is entered into between the Company and ${this.signerName || '[Consultant Name]'} for specialized consulting services.`
        };

        let baseClause = templates[this.selectedContractType] || templates['Employment'];

        // Add additional requirements if provided
        if (this.additionalRequirements) {
            baseClause += `\n\nADDITIONAL REQUIREMENTS:\n${this.additionalRequirements}`;
        }

        // Add AI-enhanced clauses if enabled
        if (this.aiProcessingEnabled) {
            baseClause += this.getAIEnhancedClauses();
        }

        return baseClause;
    }

    getAIEnhancedClauses() {
        const aiClauses = {
            'Employment': {
                'Manager': '\n\nMANAGEMENT RESPONSIBILITIES:\n- Authorized signatory privileges for company documents\n- Team leadership and performance management duties\n- Budget oversight and resource allocation authority',
                'Employee': '\n\nEMPLOYEE OBLIGATIONS:\n- Adherence to company policies and procedures\n- Professional development and training participation\n- Collaborative teamwork and communication',
                'Developer': '\n\nTECHNICAL RESPONSIBILITIES:\n- Code quality standards and best practices\n- Intellectual property assignment for developed software\n- Security protocols and data protection compliance',
                'Contractor': '\n\nCONTRACTOR PROVISIONS:\n- Independent contractor status clarification\n- Deliverable specifications and timeline requirements\n- Liability limitations and indemnification clauses'
            },
            'NDA': {
                'Manager': '\n\nMANAGEMENT NDA TERMS:\n- Executive-level confidentiality obligations\n- Strategic information protection requirements',
                'Employee': '\n\nEMPLOYEE NDA TERMS:\n- Standard confidentiality and non-disclosure provisions\n- Return of confidential materials upon termination'
            }
        };

        const roleSpecific = aiClauses[this.selectedContractType]?.[this.selectedRole] || '';
        const regionSpecific = this.getRegionSpecificClauses();

        return roleSpecific + regionSpecific;
    }

    getRegionSpecificClauses() {
        const regionClauses = {
            'US': '\n\nUS COMPLIANCE PROVISIONS:\n- At-will employment terms (where applicable)\n- Equal Employment Opportunity compliance\n- Americans with Disabilities Act adherence',
            'EU': '\n\nEU COMPLIANCE PROVISIONS:\n- GDPR data protection requirements\n- European Working Time Directive compliance\n- Cross-border data transfer provisions',
            'APAC': '\n\nAPAC COMPLIANCE PROVISIONS:\n- Local labor law compliance requirements\n- Cultural sensitivity and diversity provisions',
            'GLOBAL': '\n\nGLOBAL COMPLIANCE PROVISIONS:\n- Multi-jurisdictional legal framework adherence\n- International data transfer compliance\n- Global HR policy alignment'
        };

        return regionClauses[this.selectedRegion] || '';
    }

    async validateCompliance() {
        // Simulate compliance validation
        const complianceRules = {
            'Employment': {
                'US': { requiredTerms: ['at-will', 'equal opportunity', 'confidentiality'], score: 95 },
                'EU': { requiredTerms: ['GDPR', 'working time', 'data protection'], score: 92 }
            },
            'NDA': {
                'US': { requiredTerms: ['confidentiality', 'return of materials'], score: 98 },
                'EU': { requiredTerms: ['GDPR', 'data protection'], score: 96 }
            }
        };

        const rules = complianceRules[this.selectedContractType]?.[this.selectedRegion];

        if (!rules) {
            return {
                isCompliant: true,
                score: 85,
                analysis: 'Basic compliance validation completed',
                violations: []
            };
        }

        // Check for required terms
        const clauseText = this.generatedClause.toLowerCase();
        const missingTerms = rules.requiredTerms.filter(term => 
            !clauseText.includes(term.toLowerCase())
        );

        const isCompliant = missingTerms.length === 0;

        this.complianceDetails = {
            complianceScore: rules.score - (missingTerms.length * 10),
            analysis: isCompliant ? 
                `Document meets all ${this.selectedRegion} regulatory requirements for ${this.selectedContractType} agreements.` : 
                `Document requires review for ${this.selectedRegion} compliance standards.`,
            violations: missingTerms.map(term => `Missing required term: "${term}"`)
        };

        return {
            isCompliant,
            score: this.complianceDetails.complianceScore,
            analysis: this.complianceDetails.analysis,
            violations: this.complianceDetails.violations
        };
    }

    generateDocumentContent() {
        return `
GENERATED DOCUMENT
===================

Document ID: ${this.documentId}
Contract Type: ${this.selectedContractType}
Region: ${this.selectedRegion}
Role: ${this.selectedRole}
Generated Date: ${new Date().toLocaleDateString()}
AI Processing: ${this.aiProcessingEnabled ? 'Enabled' : 'Disabled'}

DOCUMENT CONTENT:
==================

${this.generatedClause}

SIGNATURE INFORMATION:
=======================

Signer Name: ${this.signerName}
Signer Email: ${this.signerEmail}
Signature Request ID: ${this.signatureRequestId}
Status: ${this.signatureRequestId ? 'Pending Signature' : 'Draft'}
${this.signatureInstructions ? `Instructions: ${this.signatureInstructions}` : ''}

COMPLIANCE STATUS:
==================

Status: ${this.complianceStatus?.isCompliant ? 'Compliant' : 'Requires Review'}
Score: ${this.complianceDetails?.complianceScore || 'N/A'}%
Analysis: ${this.complianceDetails?.analysis || 'No analysis available'}
${this.complianceDetails?.violations?.length > 0 ? `Violations: ${this.complianceDetails.violations.join(', ')}` : ''}
        `;
    }

    resetGenerationData() {
        this.generatedClause = '';
        this.complianceStatus = null;
        this.complianceDetails = null;
        this.documentId = '';
        this.signatureRequestId = '';
        this.emailSentStatus = false;
    }

    resetComponent() {
        // Reset all form data
        this.currentStep = 1;
        this.selectedRegion = '';
        this.selectedRole = '';
        this.selectedContractType = '';
        this.additionalRequirements = '';
        this.aiProcessingEnabled = true;
        this.signerEmail = '';
        this.signerName = '';
        this.signatureInstructions = '';
        this.selectedSignatureOptions = [];
        this.resetGenerationData();
        this.clearError();
    }

    // Utility Methods
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    showSuccessToast(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: message,
                variant: 'success'
            })
        );
    }

    showErrorToast(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error'
            })
        );
    }
}