// Phase 11: Document Save and Management Integration
public with sharing class DocumentSaveController {

    // Save a newly generated AI document
    @AuraEnabled
    public static Map<String, Object> saveGeneratedDocument(
        String content,
        String templateId,
        String folderId,
        String modelUsed,
        String parameters
    ) {
        try {
            // Create ContentVersion (the actual file)
            ContentVersion contentVersion = new ContentVersion(
                Title = generateDocumentTitle(templateId),
                PathOnClient = generateDocumentTitle(templateId) + '.html',
                VersionData = Blob.valueOf(content),
                ContentLocation = 'S', // Salesforce
                Description = 'Generated using AI model: ' + modelUsed
            );
            insert contentVersion;

            // Get the ContentDocumentId
            ContentVersion insertedVersion = [
                SELECT ContentDocumentId, Id 
                FROM ContentVersion 
                WHERE Id = :contentVersion.Id 
                LIMIT 1
            ];

            // Link to the folder
            ContentDocumentLink docLink = new ContentDocumentLink(
                ContentDocumentId = insertedVersion.ContentDocumentId,
                LinkedEntityId = folderId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
            insert docLink;

            // Create audit trail entry
            Document_Generation_Audit__c audit = new Document_Generation_Audit__c();
                audit.ContentDocumentId__c = insertedVersion.ContentDocumentId;
                audit.TemplateId__c = templateId;
                audit.FolderId__c = folderId;
                audit.AI_Model_Used__c = modelUsed;
                audit.Generation_Parameters__c = parameters;
                audit.Generation_Timestamp__c = DateTime.now();
                audit.Generated_By__c = UserInfo.getUserId();
                audit.Document_Length__c = content.length();
                audit.Status__c = 'Generated';
           
            insert audit;

            // Log activity
           /* AuditTrailManager.logDocumentActivity(
                insertedVersion.ContentDocumentId,
                'AI_DOCUMENT_GENERATED',
                'Document generated using ' + modelUsed + ' with context-aware intelligence'
            );
*/
            return new Map<String, Object>{
                'documentId' => insertedVersion.ContentDocumentId,
                'versionId' => insertedVersion.Id,
                'auditId' => audit.Id,
                'success' => true,
                'message' => 'Document saved successfully'
            };

        } catch (Exception e) {
            throw new AuraHandledException('Failed to save document: ' + e.getMessage());
        }
    }

    // Generate a document title based on template name and timestamp
    private static String generateDocumentTitle(String templateId) {
        try {
            DocumentTemplate__c template = [
                SELECT Name 
                FROM DocumentTemplate__c 
                WHERE Id = :templateId 
                LIMIT 1
            ];
            String timestamp = DateTime.now().format('yyyy-MM-dd_HH-mm');
            return template.Name + '_Generated_' + timestamp;
        } catch (Exception e) {
            String timestamp = DateTime.now().format('yyyy-MM-dd_HH-mm');
            return 'AI_Generated_Document_' + timestamp;
        }
    }

    // Retrieve all documents generated in a folder
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getGeneratedDocuments(String folderId) {
        try {
            List<Map<String, Object>> documents = new List<Map<String, Object>>();

            // Get all documents linked to this folder
            List<ContentDocumentLink> links = [
                SELECT ContentDocumentId, ContentDocument.Title, 
                       ContentDocument.CreatedDate, ContentDocument.LastModifiedDate,
                       ContentDocument.ContentSize, ContentDocument.FileType
                FROM ContentDocumentLink 
                WHERE LinkedEntityId = :folderId
                ORDER BY ContentDocument.CreatedDate DESC
            ];

            Set<Id> documentIds = new Set<Id>();
            for (ContentDocumentLink link : links) {
                documentIds.add(link.ContentDocumentId);
            }

            // Get audit information for generated documents
            Map<Id, Document_Generation_Audit__c> auditMap = new Map<Id, Document_Generation_Audit__c>();
            for (Document_Generation_Audit__c audit : [
                SELECT ContentDocumentId__c, AI_Model_Used__c, Generation_Timestamp__c,
                       TemplateId__c, TemplateId__r.Name,
                       Document_Length__c, Status__c
                FROM Document_Generation_Audit__c 
                WHERE ContentDocumentId__c IN :documentIds
            ]) {
                auditMap.put(audit.ContentDocumentId__c, audit);
            }

            // Combine document and audit information
            for (ContentDocumentLink link : links) {
                Map<String, Object> docInfo = new Map<String, Object>();
                docInfo.put('id', link.ContentDocumentId);
                docInfo.put('title', link.ContentDocument.Title);
                docInfo.put('createdDate', link.ContentDocument.CreatedDate);
                docInfo.put('lastModifiedDate', link.ContentDocument.LastModifiedDate);
                docInfo.put('contentSize', link.ContentDocument.ContentSize);
                docInfo.put('fileType', link.ContentDocument.FileType);

                Document_Generation_Audit__c audit = auditMap.get(link.ContentDocumentId);
                if (audit != null) {
                    docInfo.put('aiGenerated', true);
                    docInfo.put('aiModel', audit.AI_Model_Used__c);
                    docInfo.put('templateName', audit.TemplateId__r?.Name);
                    docInfo.put('generationDate', audit.Generation_Timestamp__c);
                    docInfo.put('status', audit.Status__c);
                } else {
                    docInfo.put('aiGenerated', false);
                }

                documents.add(docInfo);
            }

            return documents;

        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve documents: ' + e.getMessage());
        }
    }

    // Regenerate an existing document with new parameters
    @AuraEnabled
    public static void regenerateDocument(String documentId, String newParameters) {
        try {
            // Get original generation audit
            Document_Generation_Audit__c originalAudit = [
                SELECT TemplateId__c, FolderId__c, AI_Model_Used__c, 
                       Generation_Parameters__c
                FROM Document_Generation_Audit__c 
                WHERE ContentDocumentId__c = :documentId 
                LIMIT 1
            ];

            // Parse new parameters or use original
            Map<String, Object> parameters = String.isNotBlank(newParameters) 
                ? (Map<String, Object>) JSON.deserializeUntyped(newParameters)
                : (Map<String, Object>) JSON.deserializeUntyped(originalAudit.Generation_Parameters__c);

            // Get fresh folder context
            ContextAwareDocumentEngine.FolderContextAnalysis folderContext = 
                ContextAwareDocumentEngine.analyzeFolderContext(
                    originalAudit.FolderId__c, 
                    'document_regeneration'
                );

            // Generate new content
            String newContent;
            /*String newContent = ContextAwareTemplateEngine.generateContextualDocument(
                originalAudit.TemplateId__c,
                folderContext,
                parameters
            );*/

            // Update existing document with new version
            ContentVersion newVersion = new ContentVersion(
                ContentDocumentId = documentId,
                VersionData = Blob.valueOf(newContent),
                PathOnClient = 'regenerated_document.html',
                Description = 'Regenerated using AI model: ' + originalAudit.AI_Model_Used__c
            );
            insert newVersion;

            // Update audit trail
            originalAudit.Status__c = 'Regenerated';
            originalAudit.Generation_Parameters__c = JSON.serialize(parameters);
            originalAudit.Generation_Timestamp__c = DateTime.now();
            update originalAudit;

            // Log activity
           /* AuditTrailManager.logDocumentActivity(
                documentId,
                'DOCUMENT_REGENERATED',
                'Document regenerated with updated parameters'
            );*/

        } catch (Exception e) {
            throw new AuraHandledException('Failed to regenerate document: ' + e.getMessage());
        }
    }
}