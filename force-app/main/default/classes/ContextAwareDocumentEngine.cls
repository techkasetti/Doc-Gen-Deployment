public with sharing class ContextAwareDocumentEngine {

    // Lightweight wrapper for per-document context returned to UI and generators
    public class DocumentContext {
        @AuraEnabled public String documentId { get; set; }
        @AuraEnabled public String documentName { get; set; }
        @AuraEnabled public String content { get; set; }
        @AuraEnabled public Map<String, Object> metadata { get; set; }
        @AuraEnabled public List<String> extractedEntities { get; set; }
        @AuraEnabled public Decimal relevanceScore { get; set; }
        @AuraEnabled public String documentType { get; set; } // ✅ Added missing field

        public DocumentContext() {
            metadata = new Map<String, Object>();
            extractedEntities = new List<String>();
            relevanceScore = 0;
            documentType = 'UNKNOWN';
        }
    }

    // Folder-level aggregated analysis returned to controllers and LWC
    public class FolderContextAnalysis {
        @AuraEnabled public String folderId { get; set; }
        @AuraEnabled public List<DocumentContext> documents { get; set; }
        @AuraEnabled public List<String> commonThemes { get; set; }
        @AuraEnabled public Map<String, Integer> entityFrequency { get; set; }
        @AuraEnabled public String contextualSummary { get; set; }
        @AuraEnabled public List<String> suggestedTemplates { get; set; }
        @AuraEnabled public Map<String, Object> contextualInsights { get; set; }

        // ✅ Added missing field referenced in ContextAwareGenerationSupport
        @AuraEnabled public Map<String, Object> crossDocumentRelations { get; set; }

        public FolderContextAnalysis() {
            documents = new List<DocumentContext>();
            commonThemes = new List<String>();
            entityFrequency = new Map<String, Integer>();
            suggestedTemplates = new List<String>();
            contextualInsights = new Map<String, Object>();
            crossDocumentRelations = new Map<String, Object>();
        }
    }

    @AuraEnabled(cacheable=true)
    public static FolderContextAnalysis analyzeFolderContext(String folderId, String selectedAIModel) {
        FolderContextAnalysis out = new FolderContextAnalysis();
        out.folderId = folderId;
        try {
            Boolean usedAdvanced = false;
            try {
                Map<String, Object> processed = null;
                try {
                    processed = AdvancedContextProcessor.processDocumentCollection(folderId, selectedAIModel, null);
                } catch (Exception callEx) {
                    processed = null;
                }
                if (processed != null) {
                    if (processed.containsKey('documentCollection')) {
                        List<Object> docs = (List<Object>) processed.get('documentCollection');
                        for (Object o : docs) {
                            Map<String, Object> dm = (Map<String, Object>) o;
                            DocumentContext dc = new DocumentContext();
                            dc.documentId = dm.containsKey('documentId') ? String.valueOf(dm.get('documentId')) : null;
                            dc.documentName = dm.containsKey('title') ? String.valueOf(dm.get('title')) :
                                              (dm.containsKey('documentName') ? String.valueOf(dm.get('documentName')) : null);
                            dc.content = dm.containsKey('content') ? String.valueOf(dm.get('content')) : null;
                            if (dm.containsKey('metadata')) dc.metadata = (Map<String,Object>) dm.get('metadata'); 
                            if (dm.containsKey('extractedEntities')) dc.extractedEntities = (List<String>) dm.get('extractedEntities');
                            if (dm.containsKey('relevanceScore')) {
                                try { dc.relevanceScore = Decimal.valueOf(String.valueOf(dm.get('relevanceScore'))); } 
                                catch (Exception ex) { dc.relevanceScore = 0; }
                            }
                            if (dm.containsKey('documentType')) dc.documentType = String.valueOf(dm.get('documentType'));
                            out.documents.add(dc);
                        }
                    }
                    if (processed.containsKey('contextualInsights')) {
                        out.contextualInsights = (Map<String,Object>) processed.get('contextualInsights');
                        if (out.contextualInsights.containsKey('commonTopics')) {
                            List<Object> themes = (List<Object>) out.contextualInsights.get('commonTopics');
                            for (Object t : themes) out.commonThemes.add(String.valueOf(t));
                        }
                    }
                    if (processed.containsKey('suggestedTemplates')) {
                        List<Object> s = (List<Object>) processed.get('suggestedTemplates');
                        for (Object st : s) out.suggestedTemplates.add(String.valueOf(st));
                    }
                    if (processed.containsKey('entityRelationships')) {
                        Map<String,Object> er = (Map<String,Object>) processed.get('entityRelationships');
                        if (er.containsKey('entityFrequency')) {
                            out.entityFrequency = (Map<String,Integer>) er.get('entityFrequency');
                        }
                        out.crossDocumentRelations = er; // ✅ store for later usage
                    }
                    if (processed.containsKey('contextualSummary')) {
                        out.contextualSummary = String.valueOf(processed.get('contextualSummary'));
                    }
                    usedAdvanced = true;
                }
            } catch (Exception ex) { }

            if (!usedAdvanced) {
                try {
                    if (!String.isBlank(folderId) && Schema.getGlobalDescribe().containsKey('ContentDocumentLink')) {
                        List<ContentDocumentLink> links = [
                            SELECT ContentDocument.Id, ContentDocument.Title 
                            FROM ContentDocumentLink 
                            WHERE LinkedEntityId = :folderId LIMIT 50
                        ];
                        for (ContentDocumentLink l : links) {
                            DocumentContext dc = new DocumentContext();
                            dc.documentId = l.ContentDocument.Id;
                            dc.documentName = l.ContentDocument.Title;
                            out.documents.add(dc);
                        }
                    }
                    if (!out.documents.isEmpty()) out.contextualSummary = 'Basic listing of documents in the folder.';
                } catch (Exception e) {
                    out.contextualSummary = 'Folder analysis not available: ' + e.getMessage();
                }
            }
        } catch (Exception e) {
            out.contextualSummary = 'Analysis failed: ' + e.getMessage();
        }
        return out;
    }

    @AuraEnabled
    public static String generatePreviewContent(FolderContextAnalysis analysis, DocumentTemplate__c template, String selectedAIModel, Map<String, Object> parameters) {
        try {
            String base = '';
            if (template != null) {
                try {
                    if (template.getSObjectType().getDescribe().fields.getMap().containsKey('Template_Content__c')) {
                        Object tc = template.get('Template_Content__c');
                        if (tc != null) base = String.valueOf(tc);
                    }
                } catch (Exception ex) { }
                if (String.isBlank(base)) {
                    try {
                        if (template.getSObjectType().getDescribe().fields.getMap().containsKey('Name')) {
                            base = template.Name != null ? template.Name : '';
                        }
                    } catch (Exception ex) { }
                }
            }
            if (String.isBlank(base)) base = 'Generated Document';

            String contextSummary = '';
            if (analysis != null) {
                if (!String.isBlank(analysis.contextualSummary)) {
                    contextSummary = '\n\nContext Summary:\n' + analysis.contextualSummary;
                } else if (analysis.commonThemes != null && !analysis.commonThemes.isEmpty()) {
                    contextSummary = '\n\nCommon Themes: ' + String.join(analysis.commonThemes, ', ');
                } else if (analysis.documents != null && !analysis.documents.isEmpty()) {
                    contextSummary = '\n\nDocuments analyzed: ' + String.valueOf(analysis.documents.size());
                }
            }

            String merged = base;
            if (parameters != null && !parameters.isEmpty()) {
                for (String k : parameters.keySet()) {
                    String token = '{{' + k + '}}';
                    String val = parameters.get(k) != null ? String.valueOf(parameters.get(k)) : '';
                    merged = merged.replace(token, val);
                }
            }

            String modelHint = !String.isBlank(selectedAIModel) ? '\n\n(Preview created with model: ' + selectedAIModel + ')' : '';
            String preview = merged + contextSummary + modelHint;
            Integer maxLen = 20000;
            if (preview.length() > maxLen) preview = preview.substring(0, maxLen) + '\n\n[TRUNCATED]';
            return preview;
        } catch (Exception e) {
            System.debug('generatePreviewContent error: ' + e.getMessage());
            return 'Preview generation failed: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static String generateContextAwareDocument(String folderId, String templateId, String selectedAIModel, Map<String, Object> generationParameters) {
        try {
            if (String.isBlank(templateId)) {
                throw new AuraHandledException('Missing templateId');
            }
            DocumentTemplate__c template;
            try {
                template = [SELECT Id, Name, Template_Content__c, Merge_Fields__c FROM DocumentTemplate__c WHERE Id = :templateId LIMIT 1];
            } catch (Exception q) {
                throw new AuraHandledException('Template not found: ' + q.getMessage());
            }

            FolderContextAnalysis analysis;
            try {
                analysis = analyzeFolderContext(folderId, selectedAIModel);
            } catch (Exception aex) {
                analysis = new FolderContextAnalysis();
                analysis.folderId = folderId;
                analysis.contextualSummary = 'Folder analysis failed: ' + aex.getMessage();
            }

            String content = generatePreviewContent(analysis, template, selectedAIModel, generationParameters);
            if (content == null) content = '';

            ContentVersion cv = new ContentVersion();
            String title = template != null && template.Name != null ? template.Name + ' - Generated' : 'Generated Document';
            cv.Title = title;
            cv.PathOnClient = (title + '.html').replaceAll('[^a-zA-Z0-9\\.\\-_ ]', '_');
            cv.VersionData = Blob.valueOf(content);
            cv.IsMajorVersion = true;
            insert cv;

            ContentVersion got = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
            if (got == null || got.ContentDocumentId == null) {
                throw new AuraHandledException('Failed to persist generated document');
            }

            try {
                if (!String.isBlank(folderId) && Schema.getGlobalDescribe().containsKey('ContentDocumentLink')) {
                    ContentDocumentLink link = new ContentDocumentLink(ContentDocumentId = got.ContentDocumentId, LinkedEntityId = folderId, ShareType = 'V', Visibility = 'AllUsers');
                    insert link;
                }
            } catch (Exception attachEx) {
                System.debug('Warning: could not attach generated document to folder: ' + attachEx.getMessage());
            }

            return got.ContentDocumentId;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            throw new AuraHandledException('generateContextAwareDocument error: ' + e.getMessage());
        }
    }
}