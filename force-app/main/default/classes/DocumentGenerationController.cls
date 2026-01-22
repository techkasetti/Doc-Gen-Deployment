/**
* @description Central controller for Document Generation.
* Handles template management, document assembly,
* and final generation with AI model integration.
* @author Anara AI (Updated & Merged)
* @version 2.7
* @last modified on: 11-26-2025
*/
public with sharing class DocumentGenerationController {
    
    //====================================================
    // METHODS FOR: templateManager & templateEditor LWC
    //====================================================
    
    @AuraEnabled(cacheable=true)
    public static List<DocumentTemplate__c> getDocumentTemplates() {
        return [
            SELECT 
            Id, 
            Name, 
            Body__c, 
            Version__c, 
            IsActive__c,
            // --- ADD THESE THREE FIELDS ---
            Region1__c, 
            Role__c, 
            Contract_Type__c 
            FROM DocumentTemplate__c 
            ORDER BY CreatedDate DESC
        ];
    }
    
    
    @AuraEnabled
    public static Id saveTemplate(DocumentTemplate__c templateRecord) {
        if (!Schema.sObjectType.DocumentTemplate__c.isCreateable() ||
            !Schema.sObjectType.DocumentTemplate__c.isUpdateable()) {
                throw new AuraHandledException(
                    'You do not have permission to create or update Document Templates.'
                );
            }
        System.debug('templateRecord::::::'+templateRecord);
        upsert templateRecord;
        return templateRecord.Id;
    }
    
    //====================================================
    // METHODS FOR: documentGenerator LWC - UPDATED WITH AI MODEL
    //====================================================
    
    // No changes to this method
    @AuraEnabled(cacheable=true)
    public static List<DocumentTemplate__c> getActiveTemplatesForSelection() {
        return [
            SELECT Id, Name,Region1__c
            FROM DocumentTemplate__c
            WHERE IsActive__c = true
            ORDER BY CreatedDate DESC
        ];
    }
    
    
    // Fetch available AI models
    @AuraEnabled(cacheable=true)
    public static List<AIModelManager.AIModelConfig> getAvailableAIModels() {
        return AIModelManager.getAvailableAIModels();
    }
    
    // Generates a clause suggestion using the specified AI model
    @AuraEnabled
    public static String generateClauseWithAI(
        String modelId,
        String prompt,
        String jsonContext
    ) {
        try {
            String response = AIModelManager.processWithEinstein(
                modelId,
                prompt,
                jsonContext
            );
            
            ClauseGenerator.logAIGeneration(
                modelId,
                prompt,
                response,
                'Success',
                null
            );
            
            return response;
            
        } catch (Exception e) {
            ClauseGenerator.logAIGeneration(
                modelId,
                prompt,
                null,
                'Error',
                e.getMessage()
            );
            throw new AuraHandledException(
                'AI Clause Generation Failed: ' + e.getMessage()
            );
        }
    }
    
    //====================================================
    // PREVIEW DOCUMENT
    //====================================================
    
    // --- MODIFIED METHOD: PREVIEWDOCUMENT ---
    /**
* @description Generates a real-time preview by merging a template with multiple data sources.
* @param templateId The ID of the DocumentTemplate__c record.
* @param jsonData A JSON string of primary data (e.g., contact details).
* @param aiClauseText Optional AI-generated text to be merged.
* @return A PreviewResult wrapper with the rendered HTML or errors.
*/
   @AuraEnabled
public static PreviewResult previewDocument(
    Id templateId,
    String jsonData,
    String aiClauseText,
    String generatedDateTime
) {

    PreviewResult result = new PreviewResult();

    if (templateId == null) {
        result.success = false;
        result.validationErrors.add('Template ID is required.');
        return result;
    }

    try {
        // Fetch template
        DocumentTemplate__c template = [
            SELECT Name, Body__c, Version__c,
                   Region1__c, Role__c,
                   Contract_Type__c, Jurisdiction__c
            FROM DocumentTemplate__c
            WHERE Id = :templateId
            LIMIT 1
        ];

        result.templateName = template.Name;

        //  Build merge data
        Map<String, Object> masterMergeData = new Map<String, Object>();

        if (String.isNotBlank(jsonData)) {
            masterMergeData.putAll(
                (Map<String, Object>) JSON.deserializeUntyped(jsonData)
            );
        }

        masterMergeData.put('template', new Map<String, Object>{
            'Name' => template.Name,
            'Version__c' => template.Version__c,
            'Region1__c' => template.Region1__c,
            'Role__c' => template.Role__c,
            'Contract_Type__c' => template.Contract_Type__c
        });

        //  Clause resolution
        String clausestext;

        if (String.isNotBlank(aiClauseText)) {
            clausestext = aiClauseText;
        } else {
            List<Clause__c> clauses = [
                SELECT ClauseDetails__c
                FROM Clause__c
                WHERE Region__c = :template.Region1__c
                AND Role__c = :template.Role__c
                LIMIT 1
            ];

            clausestext = clauses.isEmpty()
                ? 'No clauses configured.'
                : clauses[0].ClauseDetails__c;
        }

        masterMergeData.put('aiClause', clausestext);

        //  Merge template
        String mergedHtml =
            DocumentAssemblyEngine.merge1(
                template.Body__c,
                masterMergeData
            );
            List<String> jurisdictions = new List<String>();

 if (String.isNotBlank(template.Jurisdiction__c)) {
            jurisdictions = template.Jurisdiction__c.split(';');
        } 
        
if (jurisdictions.isEmpty()) {
        if (template.Region1__c == 'EU (European Union)') {

        if (template.Contract_Type__c == 'Employment Agreement') {
            jurisdictions.add('GDPR');
            jurisdictions.add('eIDAS');
        }
        else if (template.Contract_Type__c == 'NDA') {
            jurisdictions.add('GDPR');
        }
        else if (template.Contract_Type__c == 'Statement of work') {
            jurisdictions.add('eIDAS');
        }
    }

    // ================= NORTH AMERICA =================
    else if (template.Region1__c == 'North America') {

        if (template.Contract_Type__c == 'Employment Agreement') {
            jurisdictions.add('ESIGN');
        }
        else if (template.Contract_Type__c == 'NDA') {
            jurisdictions.add('ESIGN');
        }
        else if (template.Contract_Type__c == 'Statement of work') {
            jurisdictions.add('ESIGN');
        }

        // 🔹 Future-ready example
        // if healthcare contracts exist:
        // jurisdictions.add('HIPAA');
    }

    // ================= APAC =================
    else if (template.Region1__c == 'APAC') {

        if (template.Contract_Type__c == 'Employment Agreement') {
            jurisdictions.add('IT Act India');
        }
        else if (template.Contract_Type__c == 'NDA') {
            jurisdictions.add('IT Act India');
        }
        else if (template.Contract_Type__c == 'Statement of work') {
            jurisdictions.add('IT Act India');
        }
    }

}

        //  Build LEGAL compliance section (DOCUMENT TEXT)
        String complianceSection =
            '<h3>Data Protection & Privacy</h3>';


        if (jurisdictions.contains('GDPR')) {
            complianceSection +=
                '<p><strong>GDPR:</strong> Personal data shall be processed lawfully and transparently.</p>';
        }

        if (jurisdictions.contains('eIDAS')) {
            complianceSection +=
                '<p><strong>eIDAS:</strong> Provides legal validity for electronic signatures and trust services in the EU.</p>';
        }
        if (jurisdictions.contains('ESIGN')) {
            complianceSection +=
                '<p><strong>ESIGN:</strong> Electronic signatures are legally valid.</p>';
        }

        if (jurisdictions.contains('IT Act India')) {
            complianceSection +=
                '<p><strong>IT Act 2000:</strong> Reasonable security practices shall be implemented.</p>';
        }

        if (jurisdictions.contains('HIPAA')) {
            complianceSection +=
                '<p><strong>HIPAA:</strong> Protected Health Information shall be safeguarded.</p>';
        }


//  complianceSection +=
//             '<p><strong>This Agreement may be executed electronically and shall be legally binding in accordance with the Information Technology under Act ' +
//             String.join(jurisdictions, ', ') +
//             '.</strong></p>';


complianceSection += '<p style="font-size:14px; margin-top:20px;">';
complianceSection += '<strong>Governing Law:</strong> This Agreement shall be governed by and construed in accordance';
complianceSection += 'with the laws applicable in the '+  String.join(jurisdictions, ', ') + ' jurisdiction, without regard to conflict of law principles. ';
complianceSection += '</p> <br/>';

    complianceSection +=   '<p style="font-size:13px; font-family: "Arial", "Helvetica", sans-serif;">';
complianceSection += 'This Agreement may be executed electronically and shall have the same legal effect as an original signed document.';
complianceSection += '</p>';


        //  Insert ABOVE Terms & Conditions
        if (mergedHtml.contains('Terms & Conditions')) {
            mergedHtml = mergedHtml.replace(
                'Terms & Conditions',
                complianceSection + '<hr/>' + 'Terms & Conditions'
            );
        } else {
            mergedHtml = complianceSection + mergedHtml;
        }

        // 8Compliance validation
        List<String> complianceErrors =
            ComplianceChecker.validateDocument(
                mergedHtml,
                jurisdictions,
                template.Contract_Type__c
            );

        if (!complianceErrors.isEmpty()) {
            result.success = false;
            result.validationErrors.addAll(complianceErrors);
            return result;
        }

// for document time display
String footerHtml =
    '<div style="' +
    'border-top:1px solid #ddd;' +
    'margin-top:20px;' +
    'padding-top:6px;' +
    'font-size:11px;' +
    'color:#666;' +
    'text-align:right;' +
    '">' +
    'Generated On: ' +
    generatedDateTime +
    '</div>';

// Insert footer INSIDE the document (before final closing div)
Integer lastDivIndex = mergedHtml.lastIndexOf('</div>');

if (lastDivIndex > 0) {
    mergedHtml =
        mergedHtml.substring(0, lastDivIndex) +
        footerHtml +
        mergedHtml.substring(lastDivIndex);
}



        result.renderedContent = mergedHtml;
        result.success = true;
        return result;

    } catch (Exception e) {
        result.success = false;
        result.validationErrors.add(e.getMessage());
        return result;
    }
}

    
    //====================================================
    // FINAL DOCUMENT GENERATION
    //====================================================
    
    @AuraEnabled
    public static FinalGenerationResult generateFinalDocument(
        String templateId,
        String jsonData,
        String aiClauseText,
        String selectedAIModel,
        String generatedDateTime
        
    ) {
        FinalGenerationResult result = new FinalGenerationResult();
        
        if (!Schema.sObjectType.DocumentLifecycleConfiguration__c.isCreateable() ||
            !Schema.sObjectType.ContentVersion.isCreateable()) {
                result.success = false;
                result.errorMessage =
                    'You do not have permission to create document records or files.';
                return result;
            }
        
        try {
            String decodedJsonData = jsonData.unescapeHtml4();
            
            PreviewResult preview =
                previewDocument(templateId, decodedJsonData, aiClauseText, generatedDateTime);
            
            if (!preview.success) {
                result.errorMessage =
                    String.join(preview.validationErrors, '; ');
                return result;
            }
            
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Generated Document - ' + System.now().format();
            cv.PathOnClient = cv.Title + '.html';
            cv.VersionData = Blob.valueOf(preview.renderedContent);
            cv.IsMajorVersion = true;
            
            insert cv;
            
            ContentVersion savedCv = [
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE Id = :cv.Id
                LIMIT 1
            ];
            
            if (savedCv != null) {
                DocumentLifecycleConfiguration__c docConfig =
                    new DocumentLifecycleConfiguration__c(
                        Name__c = cv.Title,
                        ContentDocumentString__c = savedCv.ContentDocumentId,
                        AI_Model_Used__c = selectedAIModel
                    );
                
                insert docConfig;
                
                result.success = true;
                result.recordId = docConfig.Id;
                result.contentDocumentId = savedCv.ContentDocumentId;
                result.aiModelUsed = selectedAIModel;
            }
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage =
                'Failed to create the document file: ' + e.getMessage();
        }
        
        return result;
    }
    
    //====================================================
    // CREATE DOCUMENT REQUEST WITH AI
    //====================================================
    
    @AuraEnabled
    public static String createDocumentRequest(
        String contractType,
        String region,
        String role,
        String additionalRequirements,
        String selectedAIModel
    ) {
        try {
            if (String.isBlank(contractType) ||
                String.isBlank(region) ||
                String.isBlank(role)) {
                    throw new AuraHandledException(
                        'Contract type, region, and role are required'
                    );
                }
            
            String generatedClause =
                ClauseGenerator.generateClause(
                    region,
                    role,
                    contractType,
                    selectedAIModel
                );
            
            if (String.isBlank(generatedClause)) {
                throw new AuraHandledException(
                    'Failed to generate document clause'
                );
            }
            
         List<String> errors =
    ComplianceChecker.validateDocument(
        generatedClause,
        new List<String>{ region },
        contractType
    );

Boolean isCompliant = errors.isEmpty();

            
            String complianceStatus =
                isCompliant ? 'COMPLIANT' : 'REQUIRES_REVIEW';
            
            DocumentLifecycleConfiguration__c docConfig =
                new DocumentLifecycleConfiguration__c(
                    Region__c = region,
                    Role__c = role,
                    ContractType__c = contractType,
                    GeneratedClause__c = generatedClause,
                    ComplianceStatus__c = complianceStatus,
                    ProcessingStatus__c = 'GENERATED',
                    AIProcessingEnabled__c = true,
                    AI_Model_Used__c = selectedAIModel
                );
            
            if (String.isNotBlank(additionalRequirements)) {
                docConfig.GeneratedClause__c +=
                    '\n\nAdditional Requirements:\n' +
                    additionalRequirements;
            }
            
            insert docConfig;
            return docConfig.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException(
                'Document generation failed: ' + e.getMessage()
            );
        }
    }
    
    //====================================================
    // METHODS FOR: documentViewer LWC
    //====================================================
    
    @AuraEnabled(cacheable=true)
    public static DocumentViewerWrapper getDocumentDetailsForViewer(
        Id recordId
    ) {
        DocumentViewerWrapper result = new DocumentViewerWrapper();
        
        result.document = [
            SELECT Id, Name, CreatedDate, ContentDocumentString__c,
            AI_Model_Used__c,
            (SELECT Id, Status__c, SignedDate__c,
             Signature_Method__c, SignerEmail__c
             FROM Signature_Requests__r
             ORDER BY CreatedDate DESC
             LIMIT 1)
            FROM DocumentLifecycleConfiguration__c
            WHERE Id = :recordId
            LIMIT 1
        ];
        
        if (!result.document.Signature_Requests__r.isEmpty()) {
            result.signatureRequest =
                result.document.Signature_Requests__r[0];
        }
        
        result.auditTrails = [
            SELECT Id, Action__c, Details__c,
            CreatedDate, User__r.Name
            FROM Audit_Trail__c
            WHERE Record_Id__c = :recordId
            ORDER BY CreatedDate DESC
        ];
        
        if (String.isNotBlank(
            result.document.ContentDocumentString__c)) {
                
                List<ContentVersion> versions = [
                    SELECT VersionData
                    FROM ContentVersion
                    WHERE ContentDocumentId =
                    :result.document.ContentDocumentString__c
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                
                if (!versions.isEmpty()) {
                    result.renderedContent =
                        versions[0].VersionData.toString();
                } else {
                    result.renderedContent =
                        'Error: Document file not found for the linked ID.';
                }
            } else {
                result.renderedContent =
                    'Error: No document has been linked to this record.';
            }
        
        return result;
    }
    @AuraEnabled
    public static Id createApprovalRequest(Id contentVersionId, Id approverId) {
        // Validate inputs to prevent errors
        if (contentVersionId == null || approverId == null) {
            throw new AuraHandledException('Content Version ID and Approver ID are required.');
        }
        
        try {
            // Create the new Document Approval record
            DocumentApproval__c newApproval = new DocumentApproval__c();
            newApproval.Document__c = contentVersionId; // Link to the document
            newApproval.Approver__c = approverId;       // Assign to the selected user
            newApproval.Status__c = 'Pending';          // Set the initial status
            
            insert newApproval;
            
            // Return the ID of the newly created approval record
            return newApproval.Id;
            
        } catch (Exception e) {
            // If something goes wrong, pass a clear error message back to the LWC
            throw new AuraHandledException('Failed to create approval request: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<DocumentLifecycleConfiguration__c>
        getDocumentsForViewer() {
            
            return [
                SELECT Id, Name, Status__c,
                CreatedDate, AI_Model_Used__c
                FROM DocumentLifecycleConfiguration__c
                ORDER BY CreatedDate DESC
                LIMIT 50
            ];
        }
    
    //====================================================
    // WRAPPER CLASSES
    //====================================================
    
    public class PreviewResult {
        @AuraEnabled public String aiModelUsed;
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String templateName { get; set; }     // Added property
        @AuraEnabled public String renderedContent { get; set; }
        @AuraEnabled public List<String> validationErrors { get; set; }
        
        public PreviewResult() {
            this.success = false;
            this.validationErrors = new List<String>();
        }
        
        
    }
    
    public class FinalGenerationResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Id recordId;
        @AuraEnabled public Id contentDocumentId;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String aiModelUsed;
        
        public FinalGenerationResult() {
            this.success = false;
        }
    }
    
    public class DocumentViewerWrapper {
        @AuraEnabled public DocumentLifecycleConfiguration__c document;
        @AuraEnabled public Signature_Request__c signatureRequest;
        @AuraEnabled public List<Audit_Trail__c> auditTrails;
        @AuraEnabled public String renderedContent;
        @AuraEnabled public String aiModelInfo;
    }
}