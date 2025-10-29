public with sharing class ContextAwareDocGenController {
    @AuraEnabled(cacheable=true)
    public static List<AIModelManager.AIModelConfig> getAIModels() {
        return AIModelManager.getAvailableAIModels();
    }

    @AuraEnabled
    public static ContextAwareDocumentEngine.FolderContextAnalysis analyzeFolderForGeneration(String folderId, String selectedAIModel) {
        try {
            return ContextAwareDocumentEngine.analyzeFolderContext(folderId, selectedAIModel);
        } catch (Exception e) {
            throw new AuraHandledException('Failed to analyze folder: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String generateDocumentWithContext(String folderId, String templateId, String selectedAIModel, Map<String, Object> generationParameters) {
        try {
            return ContextAwareDocumentEngine.generateContextAwareDocument(folderId, templateId, selectedAIModel, generationParameters);
        } catch (Exception e) {
            throw new AuraHandledException('Failed to generate document: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static List<Map<String, Object>> getDocumentSuggestions(String folderId, String selectedAIModel, String documentType) {
        try {
            ContextAwareDocumentEngine.FolderContextAnalysis analysis = ContextAwareDocumentEngine.analyzeFolderContext(folderId, selectedAIModel);
            List<Map<String, Object>> suggestions = new List<Map<String, Object>>();
            if (analysis.commonThemes != null && !analysis.commonThemes.isEmpty()) {
                for (String theme : analysis.commonThemes) {
                    Map<String, Object> suggestion = new Map<String, Object>();
                    suggestion.put('theme', theme);
                    suggestion.put('confidence', calculateThemeConfidence(theme, analysis));
                    suggestion.put('suggestedTemplates', getSuggestedTemplatesForTheme(theme));
                    suggestion.put('contextualRelevance', calculateContextualRelevance(theme, analysis));
                    suggestions.add(suggestion);
                }
            }
            return suggestions;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to get document suggestions: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> previewContextGeneration(String folderId, String templateId, String selectedAIModel, Map<String, Object> parameters) {
        try {
            Map<String, Object> preview = new Map<String, Object>();
            ContextAwareDocumentEngine.FolderContextAnalysis analysis = ContextAwareDocumentEngine.analyzeFolderContext(folderId, selectedAIModel);

            // Defensive template retrieval: only request fields that exist in org to avoid "No such column" errors
            List<String> desiredFields = new List<String>{'Id','Name','Template_Content__c','Merge_Fields__c','AI_Instructions__c'};
            List<String> availableFields = new List<String>();
            Schema.DescribeSObjectResult d = DocumentTemplate__c.sObjectType.getDescribe();
            for (String f : desiredFields) {
                if (d.fields.getMap().containsKey(f)) availableFields.add(f);
            }
            if (availableFields.isEmpty()) {
                throw new AuraHandledException('DocumentTemplate__c expected fields are not present in this org.');
            }
            String soql = 'SELECT ' + String.join(availableFields, ',') + ' FROM DocumentTemplate__c WHERE Id = :templateId LIMIT 1';
            DocumentTemplate__c template = (DocumentTemplate__c) Database.query(soql);

            String previewContent = ContextAwareDocumentEngine.generatePreviewContent(analysis, template, selectedAIModel, parameters);
            preview.put('previewText', previewContent);
            preview.put('estimatedLength', previewContent != null ? previewContent.length() * 4 : 0);
            preview.put('contextSources', analysis.documents != null ? analysis.documents.size() : 0);
            preview.put('aiModel', selectedAIModel);
            preview.put('generationTime', DateTime.now());
            return preview;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to generate preview: ' + e.getMessage());
        }
    }

    // ===== Helpers =====

    private static Decimal calculateThemeConfidence(String theme, ContextAwareDocumentEngine.FolderContextAnalysis analysis) {
        Integer themeCount = 0;
        Integer totalDocuments = (analysis.documents != null) ? analysis.documents.size() : 0;
        if (analysis.documents != null) {
            for (ContextAwareDocumentEngine.DocumentContext doc : analysis.documents) {
                if (doc.content != null && doc.content.toLowerCase().contains(theme.toLowerCase())) {
                    themeCount++;
                }
            }
        }
        return totalDocuments > 0 ? (Decimal.valueOf(themeCount) / totalDocuments) * 100 : 0;
    }

    private static List<String> getSuggestedTemplatesForTheme(String theme) {
        List<String> suggestedTemplates = new List<String>();
        try {
            // Query only if DocumentTemplate__c exists
            if (!Schema.getGlobalDescribe().containsKey('DocumentTemplate__c')) return suggestedTemplates;
            List<DocumentTemplate__c> templates = [SELECT Id, Name, Description__c FROM DocumentTemplate__c WHERE (Name LIKE :('%' + theme + '%') OR Description__c LIKE :('%' + theme + '%')) AND Is_Active__c = true LIMIT 5];
            for (DocumentTemplate__c t : templates) {
                suggestedTemplates.add(t.Name);
            }
        } catch (Exception e) {
            System.debug('Error getting suggested templates: ' + e.getMessage());
        }
        return suggestedTemplates;
    }

    // Placeholder for contextual relevance calculation
    private static Decimal calculateContextualRelevance(String theme, ContextAwareDocumentEngine.FolderContextAnalysis analysis) {
        // Keep simple default — can be replaced with a scoring algorithm later
        return 100;
    }
}