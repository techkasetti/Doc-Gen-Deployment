/**
 * @description Central controller for Document Generation. Handles template management,
 * document assembly, and final generation.
 * @author Anara AI (Updated)
 * @version 2.3
 * @last modified on : 11-20-2025
**/
public with sharing class DocumentGenerationController {

    //==============
    // METHODS FOR: templateManager & templateEditor LWC
    //==============
    @AuraEnabled(cacheable=true)
    public static List<DocumentTemplate__c> getDocumentTemplates() {
        return [SELECT Id, Name, Body__c, Version__c, IsActive__c FROM DocumentTemplate__c ORDER BY Name];
    }

    @AuraEnabled
    public static Id saveTemplate(DocumentTemplate__c templateRecord) {
        if (!Schema.sObjectType.DocumentTemplate__c.isCreateable() || !Schema.sObjectType.DocumentTemplate__c.isUpdateable()) {
            throw new AuraHandledException('You do not have permission to create or update Document Templates.');
        }
        upsert templateRecord;
        return templateRecord.Id;
    }

    //==============
    // METHODS FOR: documentGenerator LWC
    //==============
    @AuraEnabled(cacheable=true)
    public static List<DocumentTemplate__c> getActiveTemplatesForSelection() {
        return [SELECT Id, Name FROM DocumentTemplate__c WHERE IsActive__c = true ORDER BY Name];
    }

    @AuraEnabled
    public static PreviewResult previewDocument(Id templateId, String jsonData) {
        // ... (This method is unchanged and correct)
        PreviewResult result = new PreviewResult();
        List<String> validationErrors = new List<String>();
        try {
            DocumentTemplate__c template = [SELECT Body__c FROM DocumentTemplate__c WHERE Id = :templateId LIMIT 1];
            Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(jsonData);
            // Example Validation
            if (dataMap.containsKey('contact')) {
                Map<String, Object> contactMap = (Map<String, Object>) dataMap.get('contact');
                if (contactMap != null && contactMap.containsKey('IsUSCitizen')) {
                    if ((Boolean)contactMap.get('IsUSCitizen') == false) {
                        validationErrors.add('Compliance Policy Violation: Document cannot be generated for non-US citizens.');
                    }
                }
            }

            if (!validationErrors.isEmpty()) {
                result.success = false;
                result.validationErrors = validationErrors;
                return result;
            }
            result.renderedContent = DocumentAssemblyEngine.assemble(template.Body__c, jsonData);
            result.success = true;
        } catch (Exception e) {
            result.success = false;
            result.validationErrors.add('System Error during preview: ' + e.getMessage());
        }
        return result;
    }

    @AuraEnabled
    public static FinalGenerationResult generateFinalDocument(Id templateId, String jsonData) {
        // ... (This method is unchanged and correct)
        FinalGenerationResult result = new FinalGenerationResult();
        if (!Schema.sObjectType.DocumentLifecycleConfiguration__c.isCreateable() || !Schema.sObjectType.ContentVersion.isCreateable()) {
            result.success = false;
            result.errorMessage = 'You do not have permission to create document records or files.';
            return result;
        }
        try {
            String decodedJsonData = jsonData.unescapeHtml4();
            PreviewResult preview = previewDocument(templateId, decodedJsonData);
            if (!preview.success) {
                result.errorMessage = String.join(preview.validationErrors, '; ');
                return result;
            }

            ContentVersion cv = new ContentVersion();
            cv.Title = 'Generated Document - ' + System.now().format();
            cv.PathOnClient = cv.Title + '.html';
            cv.VersionData = Blob.valueOf(preview.renderedContent);
            cv.IsMajorVersion = true;
            insert cv;

            ContentVersion savedCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
            if (savedCv != null) {
                DocumentLifecycleConfiguration__c docConfig = new DocumentLifecycleConfiguration__c(
                    Name__c = cv.Title,
                    ContentDocumentString__c = savedCv.ContentDocumentId
                );
                insert docConfig;
                result.success = true;
                result.recordId = docConfig.Id;
                result.contentDocumentId = savedCv.ContentDocumentId;
            }
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Failed to create the document file: ' + e.getMessage();
        }
        return result;
    }

    //==============
    // METHOD FOR: documentViewer LWC (UPDATED)
    //==============
    @AuraEnabled(cacheable=true)
    public static DocumentViewerWrapper getDocumentDetailsForViewer(Id recordId) {
        DocumentViewerWrapper result = new DocumentViewerWrapper();

        result.document = [
            SELECT Id, Name, CreatedDate, ContentDocumentString__c,
                   (SELECT Id, Status__c, SignedDate__c, Signature_Method__c, SignerEmail__c FROM Signature_Requests__r ORDER BY CreatedDate DESC LIMIT 1)
            FROM DocumentLifecycleConfiguration__c
            WHERE Id = :recordId
            LIMIT 1
        ];

        if (!result.document.Signature_Requests__r.isEmpty()) {
            result.signatureRequest = result.document.Signature_Requests__r[0];
        }

        result.auditTrails = [
            SELECT Id, Action__c, Details__c, CreatedDate, User__r.Name
            FROM Audit_Trail__c
            WHERE Record_Id__c = :recordId
            ORDER BY CreatedDate DESC
        ];

        // *** THE FIX IS HERE ***
        // Only query for content if the link exists
        if (String.isNotBlank(result.document.ContentDocumentString__c)) {
            List<ContentVersion> versions = [
                SELECT VersionData FROM ContentVersion
                WHERE ContentDocumentId = :result.document.ContentDocumentString__c
                ORDER BY CreatedDate DESC LIMIT 1
            ];
            
            // Check if the query actually found a file before trying to access it
            if (!versions.isEmpty()) {
                result.renderedContent = versions[0].VersionData.toString();
            } else {
                result.renderedContent = '<p>Error: Document file not found for the linked ID.</p>';
            }
        } else {
            result.renderedContent = '<p>Error: No document has been linked to this record.</p>';
        }
        
        return result;
    }

    //==============
    // WRAPPER CLASSES
    //==============
    public class PreviewResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String renderedContent;
        @AuraEnabled public List<String> validationErrors;
        public PreviewResult() { this.validationErrors = new List<String>(); }
    }
    
    public class FinalGenerationResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Id recordId;
        @AuraEnabled public Id contentDocumentId;
        @AuraEnabled public String errorMessage;
        public FinalGenerationResult() { this.success = false; }
    }
    
    public class DocumentViewerWrapper {
        @AuraEnabled public DocumentLifecycleConfiguration__c document;
        @AuraEnabled public Signature_Request__c signatureRequest;
        @AuraEnabled public List<Audit_Trail__c> auditTrails;
        @AuraEnabled public String renderedContent;
    }
}