public class ContextAwareDocumentGenerator {

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
            // Step 1: Prepare generation context
            Map<String, Object> generationContext = prepareGenerationContext(
                contextAnalysis, 
                customInstructions, 
                conversationHistory
            );

            // Step 2: Load and process template
            Document_Template__c template = [
                SELECT Id, Name, Template_Content__c, Template_Type__c, AI_Instructions__c
                FROM Document_Template__c 
                WHERE Id = :templateId 
                LIMIT 1
            ];

            // Step 3: Generate AI-enhanced content
            String generatedContent = generateAIContent(
                template,
                generationContext,
                selectedAIModel,
                generationOptions
            );

            // Step 4: Apply context-aware enhancements
            String enhancedContent = applyContextualEnhancements(
                generatedContent,
                contextAnalysis,
                selectedAIModel
            );

            // Step 5: Perform compliance checks if enabled
            if (generationOptions.contains('compliance_checks')) {
                enhancedContent = performComplianceValidation(
                    enhancedContent,
                    contextAnalysis
                );
            }

            // Step 6: Add citations if enabled
            if (generationOptions.contains('citations')) {
                enhancedContent = addSourceCitations(
                    enhancedContent,
                    contextAnalysis
                );
            }

            // Step 7: Save generated document
            ContentVersion generatedDoc = saveGeneratedDocument(
                documentTitle,
                enhancedContent,
                templateId,
                selectedAIModel
            );

            result.put('success', true);
            result.put('title', documentTitle);
            result.put('content', enhancedContent);
            result.put('templateName', template.Name);
            result.put('documentId', generatedDoc.ContentDocumentId);
            result.put('generationMetadata', buildGenerationMetadata(
                template, selectedAIModel, generationOptions
            ));

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

        if (contextAnalysis.containsKey('contextualInsights')) {
            generationContext.put('insights', contextAnalysis.get('contextualInsights'));
        }

        if (contextAnalysis.containsKey('entityRelationships')) {
            generationContext.put('relationships', contextAnalysis.get('entityRelationships'));
        }

        if (conversationHistory != null && !conversationHistory.isEmpty()) {
            generationContext.put(
                'conversationContext', 
                extractConversationInsights(conversationHistory)
            );
        }

        if (String.isNotBlank(customInstructions)) {
            generationContext.put('customInstructions', customInstructions);
        }

        return generationContext;
    }

    private static String generateAIContent(
        Document_Template__c template,
        Map<String, Object> generationContext,
        String selectedAIModel,
        List<String> generationOptions
    ) {
        String aiPrompt = buildAIPrompt(template, generationContext, generationOptions);
        String generatedContent = '';

        if (selectedAIModel.startsWith('einstein_')) {
            generatedContent = callEinsteinGeneration(aiPrompt, selectedAIModel);
        } else {
            generatedContent = callExternalAIGeneration(aiPrompt, selectedAIModel);
        }

        return generatedContent;
    }

    private static String buildAIPrompt(
        Document_Template__c template,
        Map<String, Object> generationContext,
        List<String> generationOptions
    ) {
        StringBuilder promptBuilder = new StringBuilder();

        promptBuilder.append('Generate a document based on the following template and context:\n\n');
        promptBuilder.append('Template Type: ').append(template.Template_Type__c).append('\n');
        promptBuilder.append('Template Instructions: ').append(template.AI_Instructions__c).append('\n\n');

        promptBuilder.append('Document Context:\n');
        if (generationContext.containsKey('insights')) {
            promptBuilder.append('Key Insights: ').append(
                JSON.serialize(generationContext.get('insights'))
            ).append('\n');
        }

        if (generationContext.containsKey('relationships')) {
            promptBuilder.append('Document Relationships: ').append(
                JSON.serialize(generationContext.get('relationships'))
            ).append('\n');
        }

        if (!generationOptions.isEmpty()) {
            promptBuilder.append('\nGeneration Requirements:\n');
            for (String option : generationOptions) {
                promptBuilder.append('- ').append(getOptionDescription(option)).append('\n');
            }
        }

        if (generationContext.containsKey('customInstructions')) {
            promptBuilder.append('\nAdditional Instructions:\n');
            promptBuilder.append(generationContext.get('customInstructions'));
        }

        return promptBuilder.toString();
    }

    private static String applyContextualEnhancements(
        String content,
        Map<String, Object> contextAnalysis,
        String aiModel
    ) {
        String enhancedContent = content;

        if (contextAnalysis.containsKey('entityRelationships')) {
            enhancedContent = enhanceWithEntityReferences(enhancedContent, contextAnalysis);
        }

        if (contextAnalysis.containsKey('contextualInsights')) {
            enhancedContent = enhanceWithContextualInsights(enhancedContent, contextAnalysis);
        }

        return enhancedContent;
    }

    private static ContentVersion saveGeneratedDocument(
        String title,
        String content,
        String templateId,
        String aiModel
    ) {
        try {
            ContentVersion contentVersion = new ContentVersion(
                Title = title,
                PathOnClient = title + '.html',
                VersionData = Blob.valueOf(content),
                ContentLocation = 'S',
                Description = 'AI-Generated Document using model: ' + aiModel + ', Template: ' + templateId,
                Origin = 'H'
            );

            insert contentVersion;

            contentVersion = [
                SELECT Id, ContentDocumentId, Title
                FROM ContentVersion
                WHERE Id = :contentVersion.Id
                LIMIT 1
            ];

            createDocumentGenerationAuditTrail(
                contentVersion.ContentDocumentId,
                templateId,
                aiModel,
                content.length()
            );

            return contentVersion;

        } catch (Exception e) {
            throw new DmlException('Failed to save generated document: ' + e.getMessage());
        }
    }

    private static void createDocumentGenerationAuditTrail(
        String documentId,
        String templateId,
        String aiModel,
        Integer contentLength
    ) {
        try {
            AuditTrail__c auditRecord = new AuditTrail__c(
                Document_ID__c = documentId,
                Action_Type__c = 'AI_Document_Generation',
                User_ID__c = UserInfo.getUserId(),
                Timestamp__c = DateTime.now(),
                Details__c = JSON.serialize(new Map<String, Object>{
                    'templateId' => templateId,
                    'aiModel' => aiModel,
                    'contentLength' => contentLength,
                    'generationMethod' => 'Context_Aware_AI'
                }),
                IP_Address__c = getClientIPAddress(),
                Session_ID__c = UserInfo.getSessionId()
            );

            insert auditRecord;

        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Failed to create audit trail: ' + e.getMessage());
        }
    }

    // --- Additional methods for AI calls, compliance, citations, and enhancements ---
    // (Preserve the structure you already have)
}
