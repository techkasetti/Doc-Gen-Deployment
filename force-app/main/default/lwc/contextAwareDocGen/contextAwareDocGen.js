import { LightningElement, track, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAIModels from '@salesforce/apex/ContextAwareDocGenController.getAIModels';
import analyzeFolderForGeneration from '@salesforce/apex/ContextAwareDocGenController.analyzeFolderForGeneration';
import generateDocumentWithContext from '@salesforce/apex/ContextAwareDocGenController.generateDocumentWithContext';
import previewContextGeneration from '@salesforce/apex/ContextAwareDocGenController.previewContextGeneration';

export default class ContextAwareDocGen extends LightningElement {
    // Public API properties
    @api folderId;

    // Tracked properties for reactive UI
    @track selectedAIModel = '';
    @track aiModels = [];
    @track folderAnalysis = null;
    @track isAnalyzing = false;
    @track isGenerating = false;
    @track generatedContent = '';
    @track previewContent = '';
    @track showPreview = false;

    // Generation parameters configuration
    @track generationParameters = {
        includeExecutiveSummary: false,
        includeCompliance: false,
        tone: 'professional',
        audience: 'general',
        outputFormat: 'document'
    };

    // Template selection properties
    @track selectedTemplate = '';
    @track availableTemplates = [];

    /**
     * Component initialization
     */
    connectedCallback() {
        this.loadAIModels();
        this.loadAvailableTemplates();
    }

    /**
     * Load available AI models for dropdown selection
     * Maps model data to UI-friendly format with labels and capabilities
     */
    loadAIModels() {
        getAIModels()
            .then(result => {
                this.aiModels = result.map(model => ({
                    label: `${model.modelName} (${model.provider})`,
                    value: model.modelId,
                    capabilities: model.capabilities
                }));

                // Set default model if available
                if (this.aiModels.length > 0) {
                    this.selectedAIModel = this.aiModels[0].value;
                }
            })
            .catch(error => {
                this.showToast(
                    'Error',
                    'Failed to load AI models: ' + error.body.message,
                    'error'
                );
            });
    }

    /**
     * Load available document templates
     * TODO: Implement template loading from Apex controller
     */
    loadAvailableTemplates() {
        // Implementation to load templates
        // This would call an Apex method to get available templates
    }

    /**
     * Handle AI model selection change event
     * @param {Event} event - Selection change event
     */
    handleAIModelChange(event) {
        this.selectedAIModel = event.detail.value;
        
        const selectedModelLabel = event.target.options
            .find(opt => opt.value === this.selectedAIModel)?.label;
        
        this.showToast(
            'Info',
            `Selected AI Model: ${selectedModelLabel}`,
            'info'
        );

        // Re-analyze folder with new model if folder is already selected
        if (this.folderId && this.selectedAIModel) {
            this.analyzeFolderContext();
        }
    }

    /**
     * Analyze folder context using selected AI model
     * Performs document analysis and extracts themes and suggestions
     */
    analyzeFolderContext() {
        if (!this.folderId || !this.selectedAIModel) {
            this.showToast(
                'Warning',
                'Please select both a folder and AI model',
                'warning'
            );
            return;
        }

        this.isAnalyzing = true;
        
        analyzeFolderForGeneration({
            folderId: this.folderId,
            selectedAIModel: this.selectedAIModel
        })
            .then(result => {
                this.folderAnalysis = result;
                this.showAnalysisResults();
            })
            .catch(error => {
                this.showToast(
                    'Error',
                    'Failed to analyze folder: ' + error.body.message,
                    'error'
                );
            })
            .finally(() => {
                this.isAnalyzing = false;
            });
    }

    /**
     * Display folder analysis results to user
     * Shows summary of documents, themes, and template suggestions
     */
    showAnalysisResults() {
        if (!this.folderAnalysis) return;

        const {
            documents,
            commonThemes,
            suggestedTemplates
        } = this.folderAnalysis;

        const message = `Analyzed ${documents.length} documents. ` +
            `Found ${commonThemes.length} common themes. ` +
            `Suggested ${suggestedTemplates.length} templates.`;

        this.showToast('Success', message, 'success');
    }

    /**
     * Handle changes to generation parameters
     * @param {Event} event - Input change event
     */
    handleParameterChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.type === 'checkbox' 
            ? event.target.checked 
            : event.target.value;
        
        this.generationParameters[field] = value;
    }

    /**
     * Generate document preview using current settings
     * Provides a quick preview before full generation
     */
    generatePreview() {
        if (!this.validateInputs()) return;

        this.isGenerating = true;
        
        previewContextGeneration({
            folderId: this.folderId,
            templateId: this.selectedTemplate,
            selectedAIModel: this.selectedAIModel,
            parameters: this.generationParameters
        })
            .then(result => {
                this.previewContent = result.previewText;
                this.showPreview = true;
            })
            .catch(error => {
                this.showToast(
                    'Error',
                    'Failed to generate preview: ' + error.body.message,
                    'error'
                );
            })
            .finally(() => {
                this.isGenerating = false;
            });
    }

    /**
     * Generate full document with context-aware AI
     * Creates complete document based on folder analysis and parameters
     */
    generateDocument() {
        if (!this.validateInputs()) return;

        this.isGenerating = true;
        
        generateDocumentWithContext({
            folderId: this.folderId,
            templateId: this.selectedTemplate,
            selectedAIModel: this.selectedAIModel,
            generationParameters: this.generationParameters
        })
            .then(result => {
                this.generatedContent = result;
                this.showToast(
                    'Success',
                    'Document generated successfully with contextual AI intelligence',
                    'success'
                );
                this.showGeneratedDocument();
            })
            .catch(error => {
                this.showToast(
                    'Error',
                    'Failed to generate document: ' + error.body.message,
                    'error'
                );
            })
            .finally(() => {
                this.isGenerating = false;
            });
    }

    /**
     * Validate required inputs before generation
     * @returns {boolean} True if all required inputs are valid
     */
    validateInputs() {
        const validations = [
            {
                condition: !this.folderId,
                message: 'Please select a folder'
            },
            {
                condition: !this.selectedAIModel,
                message: 'Please select an AI model'
            },
            {
                condition: !this.selectedTemplate,
                message: 'Please select a document template'
            }
        ];

        for (const validation of validations) {
            if (validation.condition) {
                this.showToast('Warning', validation.message, 'warning');
                return false;
            }
        }

        return true;
    }

    /**
     * Display generated document to user
     * TODO: Implement document display logic
     * This could open a modal, navigate to a new page, or update the UI
     */
    showGeneratedDocument() {
        // Implementation to display the generated document
        // This could open a modal, navigate to a new page, or update the UI
    }

    /**
     * Show toast notification to user
     * @param {string} title - Toast title
     * @param {string} message - Toast message
     * @param {string} variant - Toast variant (success, error, warning, info)
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }

    // Computed properties for UI state management

    /**
     * Check if folder analysis is complete
     * @returns {boolean} True if analysis has been performed
     */
    get isAnalysisComplete() {
        return this.folderAnalysis !== null;
    }

    /**
     * Check if preview can be generated
     * @returns {boolean} True if all required fields are selected
     */
    get canGeneratePreview() {
        return this.selectedAIModel && 
               this.selectedTemplate && 
               this.folderId;
    }

    /**
     * Get current analysis status text for UI
     * @returns {string} Status message
     */
    get analysisStatusText() {
        if (this.isAnalyzing) {
            return `Analyzing folder content with ${this.getSelectedModelName()}...`;
        }
        
        if (this.folderAnalysis) {
            return `Analysis complete using ${this.getSelectedModelName()}`;
        }
        
        return 'No analysis performed';
    }

    /**
     * Get the display name of the currently selected AI model
     * @returns {string} Model display name or 'Unknown Model'
     */
    getSelectedModelName() {
        const model = this.aiModels.find(m => m.value === this.selectedAIModel);
        return model ? model.label : 'Unknown Model';
    }

/**
 * Tone options for document generation
 * @returns {Array} Array of tone options with labels and values
 */
get toneOptions() {
    return [
        { label: 'Professional', value: 'professional' },
        { label: 'Formal', value: 'formal' },
        { label: 'Conversational', value: 'conversational' },
        { label: 'Technical', value: 'technical' },
        { label: 'Academic', value: 'academic' },
        { label: 'Executive', value: 'executive' },
        { label: 'Legal', value: 'legal' },
        { label: 'Creative', value: 'creative' },
        { label: 'Persuasive', value: 'persuasive' },
        { label: 'Informative', value: 'informative' }
    ];
}

/**
 * Audience options for document generation
 * @returns {Array} Array of audience options with labels and values
 */
get audienceOptions() {
    return [
        { label: 'General', value: 'general' },
        { label: 'Executive Leadership', value: 'executive' },
        { label: 'Technical Team', value: 'technical' },
        { label: 'Legal Department', value: 'legal' },
        { label: 'Clients/Customers', value: 'clients' },
        { label: 'Stakeholders', value: 'stakeholders' },
        { label: 'Regulatory Bodies', value: 'regulatory' },
        { label: 'Academic Audience', value: 'academic' },
        { label: 'Internal Teams', value: 'internal' },
        { label: 'External Partners', value: 'partners' }
    ];
}

/**
 * Get generation status text for UI display
 * @returns {string} Status text for current generation state
 */
get generationStatusText() {
    if (this.isGenerating) {
        const modelName = this.getSelectedModelName();
        const tone = this.generationParameters.tone;
        return `Generating document using ${modelName} with ${tone} tone...`;
    }
    return '';
}

/**
 * Get context quality indicator based on folder analysis
 * @returns {string} Quality indicator text
 */
get contextQualityIndicator() {
    if (!this.folderAnalysis) {
        return 'No Analysis';
    }

    const docCount = this.folderAnalysis.documents.length;
    const themeCount = this.folderAnalysis.commonThemes.length;

    if (docCount >= 5 && themeCount >= 3) return 'Excellent Context';
    if (docCount >= 3 && themeCount >= 2) return 'Good Context';
    if (docCount >= 1 && themeCount >= 1) return 'Fair Context';
    
    return 'Limited Context';
}

/**
 * Determine if advanced options should be shown
 * @returns {boolean} True if advanced options should be displayed
 */
get showAdvancedOptions() {
    return this.selectedAIModel && this.folderAnalysis;
}

/**
 * Handle template selection change
 * @param {Event} event - The change event
 */
handleTemplateChange(event) {
    this.selectedTemplate = event.detail.value;
    
    const selectedOption = Array.from(event.target.options).find(
        opt => opt.value === this.selectedTemplate
    );
    
    this.showToast(
        'Info', 
        `Template selected: ${selectedOption.label}`, 
        'info'
    );
}

/**
 * Handle tone and audience parameter changes
 * @param {Event} event - The change event
 */
handleParameterChange(event) {
    const field = event.target.dataset.field || event.target.name;
    const value = event.target.type === 'checkbox' 
        ? event.target.checked 
        : event.target.value;

    this.generationParameters = {
        ...this.generationParameters,
        [field]: value
    };

    // Show contextual help based on tone selection
    if (field === 'tone') {
        this.showToneGuidance(value);
    }
}

/**
 * Show guidance based on selected tone
 * @param {string} tone - The selected tone
 */
showToneGuidance(tone) {
    const toneGuidance = {
        'professional': 'Professional tone will use formal language, clear structure, and business-appropriate terminology.',
        'conversational': 'Conversational tone will use friendly, approachable language while maintaining professionalism.',
        'technical': 'Technical tone will include industry-specific terminology and detailed explanations.',
        'legal': 'Legal tone will use precise legal language and formal document structure.',
        'executive': 'Executive tone will focus on high-level insights, strategic implications, and concise communication.',
        'academic': 'Academic tone will use scholarly language with proper citations and research-based content.',
        'creative': 'Creative tone will use engaging language and innovative presentation of ideas.',
        'persuasive': 'Persuasive tone will use compelling arguments and action-oriented language.',
        'informative': 'Informative tone will focus on clear, educational content with comprehensive details.',
        'formal': 'Formal tone will use traditional business language with structured presentation.'
    };

    const message = toneGuidance[tone] || 'Custom tone selected.';
    this.showToast('Tone Selected', message, 'info');
}

/**
 * Advanced document generation with context awareness
 */
async generateDocument() {
    if (!this.validateInputs()) {
        return;
    }

    this.isGenerating = true;

    try {
        // Add context-aware parameters
        const enhancedParameters = {
            ...this.generationParameters,
            folderContext: this.folderAnalysis,
            timestamp: new Date().toISOString(),
            userId: this.getCurrentUserId(),
            sessionId: this.generateSessionId()
        };

        const result = await generateDocumentWithContext({
            folderId: this.folderId,
            templateId: this.selectedTemplate,
            selectedAIModel: this.selectedAIModel,
            generationParameters: enhancedParameters
        });

        this.generatedContent = result;
        this.trackGenerationEvent('success');
        
        this.showToast(
            'Success', 
            `Context-aware document generated successfully using ${this.getSelectedModelName()}`, 
            'success'
        );

    } catch (error) {
        this.trackGenerationEvent('error', error.body?.message || error.message);
        
        this.showToast(
            'Error', 
            `Failed to generate document: ${error.body?.message || error.message}`, 
            'error'
        );
    } finally {
        this.isGenerating = false;
    }
}

/**
 * Save generated document
 */
async saveDocument() {
    try {
        const saveResult = await saveGeneratedDocument({
            content: this.generatedContent,
            folderId: this.folderId,
            templateId: this.selectedTemplate,
            aiModel: this.selectedAIModel,
            parameters: this.generationParameters
        });

        this.showToast('Success', 'Document saved successfully', 'success');
        
    } catch (error) {
        this.showToast(
            'Error', 
            `Failed to save document: ${error.body?.message || error.message}`, 
            'error'
        );
    }
}

// /**
//  * Download generated document
//  */
downloadDocument() {
    try {
        // Create downloadable content
        const element = document.createElement('a');
        const file = new Blob([this.generatedContent], { type: 'text/plain' });
        const currentDate = new Date().toISOString().split('T')[0];
        
        element.href = URL.createObjectURL(file);
        element.download = `context-aware-document-${currentDate}.txt`;
        
        document.body.appendChild(element);
        element.click();
        document.body.removeChild(element);

        this.showToast('Success', 'Document downloaded successfully', 'success');
        
    } catch (error) {
        this.showToast('Error', 'Failed to download document', 'error');
    }
}

/**
 * Track generation events for analytics
 * @param {string} eventType - Type of event (success, error, etc.)
 * @param {string} details - Additional details about the event
 */
trackGenerationEvent(eventType, details = '') {
    const eventData = {
        eventType: eventType,
        aiModel: this.selectedAIModel,
        templateId: this.selectedTemplate,
        folderId: this.folderId,
        tone: this.generationParameters.tone,
        audience: this.generationParameters.audience,
        timestamp: new Date().toISOString(),
        details: details
    };

    // Send to analytics service
    console.log('Generation Event Tracked:', eventData);
}

/**
 * Get current user ID
 * @returns {string} Current user ID
 */
getCurrentUserId() {
    // TODO: Implementation to get current user ID
    return 'current-user-id';
}

/**
 * Generate unique session ID
 * @returns {string} Unique session identifier
 */
generateSessionId() {
    const timestamp = Date.now();
    const randomString = Math.random().toString(36).substr(2, 9);
    return `session-${timestamp}-${randomString}`;
}

/**
 * Enhanced validation with context awareness
 * @returns {boolean} True if all inputs are valid
 */
validateInputs() {
    const requiredFields = [
        { field: this.folderId, message: 'Please select a folder' },
        { field: this.selectedAIModel, message: 'Please select an AI model' },
        { field: this.selectedTemplate, message: 'Please select a document template' }
    ];

    // Check required fields
    for (const required of requiredFields) {
        if (!required.field) {
            this.showToast('Validation Error', required.message, 'warning');
            return false;
        }
    }

    // Context-specific validation
    if (!this.folderAnalysis) {
        this.showToast('Validation Error', 'Please analyze folder context first', 'warning');
        return false;
    }

    if (this.folderAnalysis.documents.length === 0) {
        this.showToast(
            'Validation Error', 
            'Selected folder contains no documents for context analysis', 
            'warning'
        );
        return false;
    }

    return true;
}
}





// version v2
//import { LightningElement, track, wire, api } from 'lwc';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import getAIModels from '@salesforce/apex/ContextAwareDocGenController.getAIModels';
// import analyzeFolderForGeneration from '@salesforce/apex/ContextAwareDocGenController.analyzeFolderForGeneration';
// import generateDocumentWithContext from '@salesforce/apex/ContextAwareDocGenController.generateDocumentWithContext';
// import previewContextGeneration from '@salesforce/apex/ContextAwareDocGenController.previewContextGeneration';

// export default class ContextAwareDocGen extends LightningElement {
//     @api folderId;

//     @track selectedAIModel = '';
//     @track aiModels = [];
//     @track folderAnalysis = null;
//     @track isAnalyzing = false;
//     @track isGenerating = false;
//     @track generatedContent = '';
//     @track previewContent = '';
//     @track showPreview = false;

//     // Generation parameters
//     @track generationParameters = {
//         includeExecutiveSummary: false,
//         includeCompliance: false,
//         tone: 'professional',
//         audience: 'general',
//         outputFormat: 'document'
//     };

//     // Template selection
//     @track selectedTemplate = '';
//     @track availableTemplates = [];

//     connectedCallback() {
//         this.loadAIModels();
//         this.loadAvailableTemplates();
//     }

//     /** Load available AI models for dropdown */
//     loadAIModels() {
//         getAIModels()
//             .then(result => {
//                 this.aiModels = result.map(model => ({
//                     label: `${model.modelName} (${model.provider})`,
//                     value: model.modelId,
//                     capabilities: model.capabilities
//                 }));

//                 if (this.aiModels.length > 0) {
//                     this.selectedAIModel = this.aiModels[0].value;
//                 }
//             })
//             .catch(error => {
//                 this.showToast('Error', 'Failed to load AI models: ' + error.body.message, 'error');
//             });
//     }

//     /** Load available document templates */
//     loadAvailableTemplates() {
//         // TODO: Implement Apex call to fetch templates
//     }

//     /** Handle AI model selection change */
//     handleAIModelChange(event) {
//         this.selectedAIModel = event.detail.value;
//         const label = event.target.options.find(opt => opt.value === this.selectedAIModel)?.label;
//         this.showToast('Info', `Selected AI Model: ${label}`, 'info');

//         if (this.folderId && this.selectedAIModel) {
//             this.analyzeFolderContext();
//         }
//     }

//     /** Analyze folder context using selected AI model */
//     analyzeFolderContext() {
//         if (!this.folderId || !this.selectedAIModel) {
//             this.showToast('Warning', 'Please select both a folder and AI model', 'warning');
//             return;
//         }

//         this.isAnalyzing = true;
//         analyzeFolderForGeneration({
//             folderId: this.folderId,
//             selectedAIModel: this.selectedAIModel
//         })
//             .then(result => {
//                 this.folderAnalysis = result;
//                 this.showAnalysisResults();
//             })
//             .catch(error => {
//                 this.showToast('Error', 'Failed to analyze folder: ' + error.body.message, 'error');
//             })
//             .finally(() => {
//                 this.isAnalyzing = false;
//             });
//     }

//     /** Show folder analysis results */
//     showAnalysisResults() {
//         if (this.folderAnalysis) {
//             const { documents, commonThemes, suggestedTemplates } = this.folderAnalysis;
//             const message = `Analyzed ${documents.length} documents. Found ${commonThemes.length} common themes. Suggested ${suggestedTemplates.length} templates.`;
//             this.showToast('Success', message, 'success');
//         }
//     }

//     /** Handle generation parameter changes */
//     handleParameterChange(event) {
//         const field = event.target.dataset.field;
//         const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
//         this.generationParameters[field] = value;
//     }

//     /** Generate document preview */
//     generatePreview() {
//         if (!this.validateInputs()) return;

//         this.isGenerating = true;
//         previewContextGeneration({
//             folderId: this.folderId,
//             templateId: this.selectedTemplate,
//             selectedAIModel: this.selectedAIModel,
//             parameters: this.generationParameters
//         })
//             .then(result => {
//                 this.previewContent = result.previewText;
//                 this.showPreview = true;
//             })
//             .catch(error => {
//                 this.showToast('Error', 'Failed to generate preview: ' + error.body.message, 'error');
//             })
//             .finally(() => {
//                 this.isGenerating = false;
//             });
//     }

//     /** Generate full document with context */
//     generateDocument() {
//         if (!this.validateInputs()) return;

//         this.isGenerating = true;
//         generateDocumentWithContext({
//             folderId: this.folderId,
//             templateId: this.selectedTemplate,
//             selectedAIModel: this.selectedAIModel,
//             generationParameters: this.generationParameters
//         })
//             .then(result => {
//                 this.generatedContent = result;
//                 this.showToast('Success', 'Document generated successfully with contextual AI intelligence', 'success');
//                 this.showGeneratedDocument();
//             })
//             .catch(error => {
//                 this.showToast('Error', 'Failed to generate document: ' + error.body.message, 'error');
//             })
//             .finally(() => {
//                 this.isGenerating = false;
//             });
//     }

//     /** Validate required inputs */
//     validateInputs() {
//         if (!this.folderId) {
//             this.showToast('Warning', 'Please select a folder', 'warning');
//             return false;
//         }
//         if (!this.selectedAIModel) {
//             this.showToast('Warning', 'Please select an AI model', 'warning');
//             return false;
//         }
//         if (!this.selectedTemplate) {
//             this.showToast('Warning', 'Please select a document template', 'warning');
//             return false;
//         }
//         return true;
//     }

//     /** Show generated document */
//     showGeneratedDocument() {
//         // TODO: Implement UI logic to display generated document
//     }

//     /** Show toast message */
//     showToast(title, message, variant) {
//         this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
//     }

//     /** Getters for UI state */
//     get isAnalysisComplete() {
//         return this.folderAnalysis !== null;
//     }

//     get canGeneratePreview() {
//         return this.selectedAIModel && this.selectedTemplate && this.folderId;
//     }

//     get analysisStatusText() {
//         if (this.isAnalyzing) {
//             return `Analyzing folder content with ${this.getSelectedModelName()}...`;
//         }
//         if (this.folderAnalysis) {
//             return `Analysis complete using ${this.getSelectedModelName()}`;
//         }
//         return 'No analysis performed';
//     }

//     getSelectedModelName() {
//         const model = this.aiModels.find(m => m.value === this.selectedAIModel);
//         return model ? model.label : 'Unknown Model';
//     }

//     // Tone options for document generation
// get toneOptions() {
//     return [
//         { label: 'Professional', value: 'professional' },
//         { label: 'Formal', value: 'formal' },
//         { label: 'Conversational', value: 'conversational' },
//         { label: 'Technical', value: 'technical' },
//         { label: 'Academic', value: 'academic' },
//         { label: 'Executive', value: 'executive' },
//         { label: 'Legal', value: 'legal' },
//         { label: 'Creative', value: 'creative' },
//         { label: 'Persuasive', value: 'persuasive' },
//         { label: 'Informative', value: 'informative' }
//     ];
// }

// // Audience options for document generation
// get audienceOptions() {
//     return [
//         { label: 'General', value: 'general' },
//         { label: 'Executive Leadership', value: 'executive' },
//         { label: 'Technical Team', value: 'technical' },
//         { label: 'Legal Department', value: 'legal' },
//         { label: 'Clients/Customers', value: 'clients' },
//         { label: 'Stakeholders', value: 'stakeholders' },
//         { label: 'Regulatory Bodies', value: 'regulatory' },
//         { label: 'Academic Audience', value: 'academic' },
//         { label: 'Internal Teams', value: 'internal' },
//         { label: 'External Partners', value: 'partners' }
//     ];
// }

// /** Handle template selection change */
// handleTemplateChange(event) {
//     this.selectedTemplate = event.detail.value;
//     const label = event.target.options.find(opt => opt.value === this.selectedTemplate)?.label;
//     this.showToast('Info', 'Template selected: ' + label, 'info');
// }

// /** Handle tone and audience parameter changes */
// handleParameterChange(event) {
//     const field = event.target.dataset.field || event.target.name;
//     const value = event.target.type === 'checkbox' ? event.target.checked : event.target.value;

//     this.generationParameters = {
//         ...this.generationParameters,
//         [field]: value
//     };

//     if (field === 'tone') {
//         this.showToneGuidance(value);
//     }
// }

// /** Show guidance based on selected tone */
// showToneGuidance(tone) {
//     const toneGuidance = {
//         professional: 'Professional tone will use formal language, clear structure, and business-appropriate terminology.',
//         conversational: 'Conversational tone will use friendly, approachable language while maintaining professionalism.',
//         technical: 'Technical tone will include industry-specific terminology and detailed explanations.',
//         legal: 'Legal tone will use precise legal language and formal document structure.',
//         executive: 'Executive tone will focus on high-level insights, strategic implications, and concise communication.',
//         academic: 'Academic tone will use scholarly language with proper citations and research-based content.',
//         creative: 'Creative tone will use engaging language and innovative presentation of ideas.',
//         persuasive: 'Persuasive tone will use compelling arguments and action-oriented language.',
//         informative: 'Informative tone will focus on clear, educational content with comprehensive details.',
//         formal: 'Formal tone will use traditional business language with structured presentation.'
//     };

//     const message = toneGuidance[tone] || 'Custom tone selected.';
//     this.showToast('Tone Selected', message, 'info');
// }

// /** Advanced document generation with context awareness */
// async generateDocument() {
//     if (!this.validateInputs()) return;
//     this.isGenerating = true;

//     try {
//         const enhancedParameters = {
//             ...this.generationParameters,
//             folderContext: this.folderAnalysis,
//             timestamp: new Date().toISOString(),
//             userId: this.getCurrentUserId(),
//             sessionId: this.generateSessionId()
//         };

//         const result = await generateDocumentWithContext({
//             folderId: this.folderId,
//             templateId: this.selectedTemplate,
//             selectedAIModel: this.selectedAIModel,
//             generationParameters: enhancedParameters
//         });

//         this.generatedContent = result;
//         this.trackGenerationEvent('success');
//         this.showToast('Success', 'Context-aware document generated successfully using ' + this.getSelectedModelName(), 'success');
//     } catch (error) {
//         this.trackGenerationEvent('error', error.body.message);
//         this.showToast('Error', 'Failed to generate document: ' + error.body.message, 'error');
//     } finally {
//         this.isGenerating = false;
//     }
// }

// /** Save generated document */
// async saveDocument() {
//     try {
//         const saveResult = await saveGeneratedDocument({
//             content: this.generatedContent,
//             folderId: this.folderId,
//             templateId: this.selectedTemplate,
//             aiModel: this.selectedAIModel,
//             parameters: this.generationParameters
//         });

//         this.showToast('Success', 'Document saved successfully', 'success');
//     } catch (error) {
//         this.showToast('Error', 'Failed to save document: ' + error.body.message, 'error');
//     }
// }

// /** Download generated document */
// downloadDocument() {
//     try {
//         const element = document.createElement('a');
//         const file = new Blob([this.generatedContent], { type: 'text/plain' });
//         element.href = URL.createObjectURL(file);
//         element.download = `context-aware-document-${new Date().toISOString().split('T')[0]}.txt`;
//         document.body.appendChild(element);
//         element.click();
//         document.body.removeChild(element);

//         this.showToast('Success', 'Document downloaded successfully', 'success');
//     } catch (error) {
//         this.showToast('Error', 'Failed to download document', 'error');
//     }
// }

// /** Track generation events for analytics */
// trackGenerationEvent(eventType, details = '') {
//     const eventData = {
//         eventType,
//         aiModel: this.selectedAIModel,
//         templateId: this.selectedTemplate,
//         folderId: this.folderId,
//         tone: this.generationParameters.tone,
//         audience: this.generationParameters.audience,
//         timestamp: new Date().toISOString(),
//         details
//     };

//     console.log('Generation Event Tracked:', eventData);
// }

// /** Utility methods */
// getCurrentUserId() {
//     return 'current-user-id'; // Stubbed for now
// }

// generateSessionId() {
//     return 'session-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
// }

// /** Enhanced validation with context awareness */
// validateInputs() {
//     const requiredFields = [
//         { field: this.folderId, message: 'Please select a folder' },
//         { field: this.selectedAIModel, message: 'Please select an AI model' },
//         { field: this.selectedTemplate, message: 'Please select a document template' }
//     ];

//     for (const required of requiredFields) {
//         if (!required.field) {
//             this.showToast('Validation Error', required.message, 'warning');
//             return false;
//         }
//     }

//     if (!this.folderAnalysis) {
//         this.showToast('Validation Error', 'Please analyze folder context first', 'warning');
//         return false;
//     }

//     if (this.folderAnalysis.documents.length === 0) {
//         this.showToast('Validation Error', 'Selected folder contains no documents for context analysis', 'warning');
//         return false;
//     }

//     return true;
// }

// /** Advanced getters for UI state management */
// get generationStatusText() {
//     return this.isGenerating
//         ? `Generating document using ${this.getSelectedModelName()} with ${this.generationParameters.tone} tone...`
//         : '';
// }

// get contextQualityIndicator() {
//     if (!this.folderAnalysis) return 'No Analysis';

//     const docCount = this.folderAnalysis.documents.length;
//     const themeCount = this.folderAnalysis.commonThemes.length;

//     if (docCount >= 5 && themeCount >= 3) return 'Excellent Context';
//     if (docCount >= 3 && themeCount >= 2) return 'Good Context';
//     if (docCount >= 1 && themeCount >= 1) return 'Fair Context';
//     return 'Limited Context';
// }

// get showAdvancedOptions() {
//     return this.selectedAIModel && this.folderAnalysis;
// }

// }


// import { LightningElement, api, track } from 'lwc';
// import getAIModels from '@salesforce/apex/AIModelManager.getAvailableAIModels';
// import analyzeFolderContext from '@salesforce/apex/ContextAwareDocumentEngine.analyzeFolderContext';
// import generateContextAwareDocument from '@salesforce/apex/DocumentGenerationEngine.generateContextAwareDocument';

// export default class ContextAwareDocGen extends LightningElement {
//     @api recordId; // Folder ID

//     @track selectedAIModel = '';
//     @track aiModelOptions = [];
//     @track folderContext = null;
//     @track isAnalyzing = false;
//     @track generateDisabled = true;

//     connectedCallback() {
//         this.loadAIModels();
//     }

//     async loadAIModels() {
//         try {
//             const models = await getAIModels();
//             this.aiModelOptions = models.map(model => ({
//                 label: `${model.modelName} (${model.provider})`,
//                 value: model.modelId
//             }));
//         } catch (error) {
//             console.error('Error loading AI models:', error);
//         }
//     }

//     handleAIModelChange(event) {
//         this.selectedAIModel = event.detail.value;
//         this.generateDisabled = !this.selectedAIModel || !this.folderContext;
//     }

//     async handleAnalyzeFolderContext() {
//         if (!this.selectedAIModel) {
//             this.showToast('Error', 'Please select an AI model first', 'error');
//             return;
//         }

//         this.isAnalyzing = true;

//         try {
//             this.folderContext = await analyzeFolderContext({
//                 folderId: this.recordId,
//                 selectedAIModel: this.selectedAIModel
//             });

//             this.generateDisabled = false;
//             this.showToast('Success', 'Folder context analyzed successfully', 'success');
//         } catch (error) {
//             console.error('Context analysis error:', error);
//             this.showToast('Error', 'Failed to analyze folder context', 'error');
//         } finally {
//             this.isAnalyzing = false;
//         }
//     }

//     get contextInsights() {
//         if (!this.folderContext?.contextualInsights) return [];

//         const insights = this.folderContext.contextualInsights;
//         return Object.keys(insights).map(key => ({
//             key,
//             label: this.formatInsightLabel(key),
//             value: insights[key]
//         }));
//     }

//     formatInsightLabel(key) {
//         return key
//             .replace(/([A-Z])/g, ' $1')
//             .replace(/^./, str => str.toUpperCase());
//     }

//     get formattedTimestamp() {
//         return this.folderContext?.analysisTimestamp
//             ? new Date(this.folderContext.analysisTimestamp).toLocaleString()
//             : '';
//     }

//     showToast(title, message, variant) {
//         const evt = new CustomEvent('showtoast', {
//             detail: { title, message, variant }
//         });
//         this.dispatchEvent(evt);
//     }
// }