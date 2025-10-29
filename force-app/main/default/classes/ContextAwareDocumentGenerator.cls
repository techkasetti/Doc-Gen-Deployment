public with sharing class ContextAwareDocumentGenerator {

    @AuraEnabled
    public static Map<String, Object> generateDocument(
        Map<String, Object> contextAnalysis,
        String templateId,
        String documentTitle,
        String customInstructions,
        List<String> generationOptions,
        String selectedAIModel,
        List<Map<String, Object>> conversationHistory
    ) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            Map<String, Object> generationContext = prepareGenerationContext(contextAnalysis, customInstructions, conversationHistory);

            DocumentTemplate__c template = null;
            try {
                if (Schema.getGlobalDescribe().containsKey('DocumentTemplate__c')) {
                    template = [SELECT Id, Name, Template_Content__c, Template_Type__c, AI_Instructions__c
                                FROM DocumentTemplate__c WHERE Id = :templateId LIMIT 1];
                }
            } catch (Exception ex) {
                throw new AuraHandledException('Template retrieval failed: ' + ex.getMessage());
            }

            String generatedContent = generateAIContent(template, generationContext, selectedAIModel, generationOptions);
            String enhancedContent = applyContextualEnhancements(generatedContent, contextAnalysis, selectedAIModel);

            try {
                if (generationOptions != null && generationOptions.contains('compliance_checks')) {
                    enhancedContent = performComplianceValidation(enhancedContent, contextAnalysis);
                }
            } catch (Exception cx) {
                System.debug('Compliance validation warning: ' + cx.getMessage());
            }

            try {
                if (generationOptions != null && generationOptions.contains('citations')) {
                    enhancedContent = addSourceCitations(enhancedContent, contextAnalysis);
                }
            } catch (Exception cx) {
                System.debug('Citation insertion warning: ' + cx.getMessage());
            }

            ContentVersion generatedDoc = saveGeneratedDocument(documentTitle, enhancedContent, templateId, selectedAIModel);

            result.put('success', true);
            result.put('title', documentTitle);
            result.put('content', enhancedContent);
            result.put('templateName', template != null ? template.Name : null);
            result.put('documentId', generatedDoc != null ? generatedDoc.ContentDocumentId : null);
            result.put('generationMetadata', buildGenerationMetadata(template, selectedAIModel, generationOptions));
        } catch (Exception e) {
            result.put('success', false);
            result.put('error', 'Document generation failed: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Document generation error: ' + e.getStackTraceString());
        }
        return result;
    }

    private static Map<String, Object> prepareGenerationContext(
        Map<String, Object> contextAnalysis,
        String customInstructions,
        List<Map<String, Object>> conversationHistory
    ) {
        Map<String, Object> generationContext = new Map<String, Object>();
        if (contextAnalysis != null && contextAnalysis.containsKey('contextualInsights')) {
            generationContext.put('insights', contextAnalysis.get('contextualInsights'));
        }
        if (contextAnalysis != null && contextAnalysis.containsKey('entityRelationships')) {
            generationContext.put('relationships', contextAnalysis.get('entityRelationships'));
        }
        if (conversationHistory != null && !conversationHistory.isEmpty()) {
            generationContext.put('conversationContext', extractConversationInsights(conversationHistory));
        }
        if (String.isNotBlank(customInstructions)) {
            generationContext.put('customInstructions', customInstructions);
        }
        return generationContext;
    }

    private static String generateAIContent(
        DocumentTemplate__c template,
        Map<String, Object> generationContext,
        String selectedAIModel,
        List<String> generationOptions
    ) {
        String aiPrompt = buildAIPrompt(template, generationContext, generationOptions);
        String generatedContent = '';
        try {
            if (!String.isBlank(selectedAIModel) && selectedAIModel.startsWith('einstein_')) {
                generatedContent = callEinsteinGeneration(aiPrompt, selectedAIModel);
            } else {
                generatedContent = callExternalAIGeneration(aiPrompt, selectedAIModel);
            }
            if (String.isBlank(generatedContent)) generatedContent = aiPrompt;
        } catch (Exception e) {
            System.debug('AI generation failed, falling back to template merge: ' + e.getMessage());
            generatedContent = mergeTemplateWithContext(template, generationContext);
        }
        return generatedContent;
    }

    private static String buildAIPrompt(
        DocumentTemplate__c template,
        Map<String, Object> generationContext,
        List<String> generationOptions
    ) {
        String promptBuilder = '';
        promptBuilder += 'Generate a document based on the following template and context:\n\n';

        try {
            if (template != null && template.getSObjectType().getDescribe().fields.getMap().containsKey('Template_Type__c')) {
                promptBuilder += 'Template Type: ' + String.valueOf(template.get('Template_Type__c')) + '\n';
            } else if (template != null && template.Name != null) {
                promptBuilder += 'Template: ' + template.Name + '\n';
            }
        } catch (Exception e) {}

        try {
            if (template != null && template.getSObjectType().getDescribe().fields.getMap().containsKey('AI_Instructions__c')) {
                Object aiInstr = template.get('AI_Instructions__c');
                if (aiInstr != null) promptBuilder += 'Template Instructions: ' + String.valueOf(aiInstr) + '\n\n';
            }
        } catch (Exception e) {}

        promptBuilder += 'Document Context:\n';
        if (generationContext != null && generationContext.containsKey('insights')) {
            promptBuilder += 'Key Insights: ' + JSON.serialize(generationContext.get('insights')) + '\n';
        }
        if (generationContext != null && generationContext.containsKey('relationships')) {
            promptBuilder += 'Document Relationships: ' + JSON.serialize(generationContext.get('relationships')) + '\n';
        }

        if (generationOptions != null && !generationOptions.isEmpty()) {
            promptBuilder += '\nGeneration Requirements:\n';
            for (String option : generationOptions) {
                promptBuilder += '- ' + getOptionDescription(option) + '\n';
            }
        }

        if (generationContext != null && generationContext.containsKey('customInstructions')) {
            promptBuilder += '\nAdditional Instructions:\n';
            promptBuilder += String.valueOf(generationContext.get('customInstructions'));
        }

        return promptBuilder;
    }

    private static String applyContextualEnhancements(String content, Map<String, Object> contextAnalysis, String aiModel) {
        String enhancedContent = content;
        try {
            if (contextAnalysis != null && contextAnalysis.containsKey('entityRelationships')) {
                enhancedContent = enhanceWithEntityReferences(enhancedContent, contextAnalysis);
            }
        } catch (Exception e) {
            System.debug('enhanceWithEntityReferences warning: ' + e.getMessage());
        }
        try {
            if (contextAnalysis != null && contextAnalysis.containsKey('contextualInsights')) {
                enhancedContent = enhanceWithContextualInsights(enhancedContent, contextAnalysis);
            }
        } catch (Exception e) {
            System.debug('enhanceWithContextualInsights warning: ' + e.getMessage());
        }
        return enhancedContent;
    }

    private static ContentVersion saveGeneratedDocument(String title, String content, String templateId, String aiModel) {
        try {
            SObject cv = Schema.getGlobalDescribe().get('ContentVersion').newSObject();
            if (cv.getSObjectType().getDescribe().fields.getMap().containsKey('Title')) cv.put('Title', title);
            if (cv.getSObjectType().getDescribe().fields.getMap().containsKey('PathOnClient')) cv.put('PathOnClient', (title != null ? title : 'generated_document') + '.html');
            if (cv.getSObjectType().getDescribe().fields.getMap().containsKey('VersionData')) cv.put('VersionData', Blob.valueOf(content != null ? content : ''));
            if (cv.getSObjectType().getDescribe().fields.getMap().containsKey('Description')) cv.put('Description', 'AI-Generated Document using model: ' + aiModel + ', Template: ' + templateId);
            if (cv.getSObjectType().getDescribe().fields.getMap().containsKey('ContentLocation')) cv.put('ContentLocation', 'S');
            if (cv.getSObjectType().getDescribe().fields.getMap().containsKey('Origin')) cv.put('Origin', 'H');

            insert cv;
            Id cvId = (Id) cv.get('Id');
            ContentVersion contentVersion = [SELECT Id, ContentDocumentId, Title FROM ContentVersion WHERE Id = :cvId LIMIT 1];
            createDocumentGenerationAuditTrail(contentVersion.ContentDocumentId, templateId, aiModel, content != null ? content.length() : 0);
            return contentVersion;
        } catch (Exception e) {
            throw new DmlException('Failed to save generated document: ' + e.getMessage());
        }
    }

    private static void createDocumentGenerationAuditTrail(String documentId, String templateId, String aiModel, Integer contentLength) {
        try {
            if (!Schema.getGlobalDescribe().containsKey('AuditTrail__c')) return;
            Schema.SObjectType atType = AuditTrail__c.sObjectType;
            Map<String, Schema.SObjectField> fields = atType.getDescribe().fields.getMap();

            AuditTrail__c audit = new AuditTrail__c();
            if (fields.containsKey('Document_ID__c')) audit.put('Document_ID__c', documentId);
            if (fields.containsKey('Action_Type__c')) audit.put('Action_Type__c', 'AI_Document_Generation');
            if (fields.containsKey('User_ID__c')) audit.put('User_ID__c', UserInfo.getUserId());
            if (fields.containsKey('Timestamp__c')) audit.put('Timestamp__c', DateTime.now());
            if (fields.containsKey('Details__c')) {
                audit.put('Details__c', JSON.serialize(new Map<String, Object>{
                    'templateId' => templateId,
                    'aiModel' => aiModel,
                    'contentLength' => contentLength,
                    'generationMethod' => 'Context_Aware_AI'
                }));
            }
            if (fields.containsKey('IP_Address__c')) audit.put('IP_Address__c', getClientIPAddress());
            if (fields.containsKey('Session_ID__c')) {
                try {
                    String sid = UserInfo.getSessionId();
                    if (!String.isBlank(sid)) audit.put('Session_ID__c', sid);
                } catch (Exception ignore) {}
            }
            insert audit;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Failed to create audit trail: ' + e.getMessage());
        }
    }

    private static String getOptionDescription(String option) {
        if (String.isBlank(option)) return 'Unknown option';
        switch on option.toLowerCase() {
            when 'compliance_checks' { return 'Run automated compliance checks and include violations.'; }
            when 'citations' { return 'Insert source citations and attribution where applicable.'; }
            when else { return 'Option: ' + option; }
        }
    }

    private static String mergeTemplateWithContext(DocumentTemplate__c template, Map<String, Object> generationContext) {
        String base = '';
        try {
            if (template != null) {
                if (template.getSObjectType().getDescribe().fields.getMap().containsKey('Template_Content__c')) {
                    base = (String) template.get('Template_Content__c');
                }
                if (String.isBlank(base) && template.Name != null) base = template.Name;
            }
        } catch (Exception e) {
            base = (template != null && template.Name != null) ? template.Name : 'Generated Document';
        }
        if (generationContext != null && !generationContext.isEmpty()) {
            for (String k : generationContext.keySet()) {
                String token = '{{' + k + '}}';
                String v = generationContext.get(k) != null ? String.valueOf(generationContext.get(k)) : '';
                base = base.replace(token, v);
            }
        }
        return base;
    }

    private static String callEinsteinGeneration(String prompt, String modelId) {
        return 'AI (Einstein) Generated Content\n\n' + (prompt != null ? prompt.substring(0, Math.min(prompt.length(), 300)) : '');
    }

    private static String callExternalAIGeneration(String prompt, String modelId) {
        return 'AI (External) Generated Content\n\n' + (prompt != null ? prompt.substring(0, Math.min(prompt.length(), 300)) : '');
    }

    private static String enhanceWithEntityReferences(String content, Map<String, Object> contextAnalysis) {
        try {
            if (content == null) return null;
            if (contextAnalysis == null) return content;
            if (!contextAnalysis.containsKey('entityRelationships')) return content;
            Map<String, Object> er = (Map<String, Object>) contextAnalysis.get('entityRelationships');
            if (er.containsKey('topEntities')) {
                List<Object> top = (List<Object>) er.get('topEntities');
                if (!top.isEmpty()) {
                    List<String> names = new List<String>();
                    for (Object o : top) if (o != null) names.add(String.valueOf(o));
                    if (!names.isEmpty()) content += '\n\nTop referenced entities: ' + String.join(names, ', ');
                }
            }
        } catch (Exception e) {
            System.debug('enhanceWithEntityReferences fallback error: ' + e.getMessage());
        }
        return content;
    }

    private static String enhanceWithContextualInsights(String content, Map<String, Object> contextAnalysis) {
        try {
            if (content == null) return null;
            if (contextAnalysis == null) return content;
            if (contextAnalysis.containsKey('contextualInsights')) {
                content += '\n\nContextual Insights:\n' + JSON.serialize(contextAnalysis.get('contextualInsights'));
            }
        } catch (Exception e) {
            System.debug('enhanceWithContextualInsights fallback error: ' + e.getMessage());
        }
        return content;
    }

    private static String performComplianceValidation(String content, Map<String, Object> contextAnalysis) {
        try {
            if (Type.forName('ComplianceChecker') != null) {}
        } catch (Exception e) {
            System.debug('performComplianceValidation fallback: ' + e.getMessage());
        }
        return content;
    }

    private static String addSourceCitations(String content, Map<String, Object> contextAnalysis) {
        try {
            if (content == null) return null;
            if (contextAnalysis != null && contextAnalysis.containsKey('contextualInsights')) {
                content += '\n\nSources:\n' + '[See contextual insights]';
            }
        } catch (Exception e) {
            System.debug('addSourceCitations fallback: ' + e.getMessage());
        }
        return content;
    }

    private static Map<String, Object> extractConversationInsights(List<Map<String, Object>> conversationHistory) {
        Map<String, Object> out = new Map<String, Object>();
        try {
            List<String> history = new List<String>();
            for (Map<String, Object> turn : conversationHistory) {
                if (turn.containsKey('utterance')) history.add(String.valueOf(turn.get('utterance')));
            }
            out.put('history', history);
            out.put('length', history.size());
        } catch (Exception e) {
            out.put('error', 'extractConversationInsights failed: ' + e.getMessage());
        }
        return out;
    }

    private static Map<String, Object> buildGenerationMetadata(DocumentTemplate__c template, String aiModel, List<String> generationOptions) {
        Map<String, Object> meta = new Map<String, Object>();
        meta.put('generatedAt', DateTime.now());
        meta.put('aiModel', aiModel);
        meta.put('templateId', template != null ? template.Id : null);
        meta.put('options', generationOptions);
        return meta;
    }

    private static String getClientIPAddress() {
        try {
            return '0.0.0.0';
        } catch (Exception e) {
            return null;
        }
    }
}