private class EntityFrequency implements Comparable {
    public String entity;
    public Integer frequency;
    
    public EntityFrequency(String entity, Integer frequency) {
        this.entity = entity;
        this.frequency = frequency;
    }
    
    public Integer compareTo(Object other) {
        EntityFrequency otherEntity = (EntityFrequency) other;
        return otherEntity.frequency - this.frequency; // Descending order
    }


@AuraEnabled
public static String generateContextAwareDocument(
    String folderId,
    String templateId,
    String selectedAIModel,
    Map<String, Object> generationParameters
) {
    try {
        // Step 1: Analyze folder context
        FolderContextAnalysis contextAnalysis = analyzeFolderContext(folderId, selectedAIModel);
        
        // Step 2: Retrieve template
        DocumentTemplate__c template = [
            SELECT Id, Template_Content__c, Template_Variables__c, AI_Prompts__c
            FROM DocumentTemplate__c 
            WHERE Id = :templateId 
            LIMIT 1
        ];
        
        // Step 3: Generate context-aware content
        String generatedContent = generateContentWithContext(
            template, 
            contextAnalysis, 
            selectedAIModel,
            generationParameters
        );
        
        // Step 4: Save generated document
        Document__c newDoc = new Document__c(
            Name = 'Context-Aware Generated Document',
            Content__c = generatedContent,
            Template_Used__c = templateId,
            AI_Model__c = selectedAIModel,
            Context_Analysis__c = JSON.serialize(contextAnalysis),
            Generated_Date__c = DateTime.now()
        );
        
        insert newDoc;
        
        return newDoc.Id;
        
    } catch (Exception e) {
        throw new AuraHandledException('Document generation failed: ' + e.getMessage());
    }
}

private static String generateContentWithContext(
    DocumentTemplate__c template,
    FolderContextAnalysis contextAnalysis,
    String selectedAIModel,
    Map<String, Object> generationParameters
) {
    // Prepare AI prompt with context
    Map<String, Object> aiParameters = new Map<String, Object>{
        'template' => template.Template_Content__c,
        'context' => contextAnalysis,
        'parameters' => generationParameters,
        'instruction' => 'Generate a document using the provided template and context. ' +
                        'Incorporate insights from the analyzed documents while maintaining ' +
                        'consistency with the template structure.'
    };
    
    String prompt = buildContextAwarePrompt(template, contextAnalysis, generationParameters);
    
    // Call AI model for generation
    String response = AIModelManager.processWithEinstein(selectedAIModel, prompt, aiParameters);
    
    // Process and clean the response
    return processGeneratedContent(response, template);
}

private static String buildContextAwarePrompt(
    DocumentTemplate__c template,
    FolderContextAnalysis contextAnalysis,
    Map<String, Object> generationParameters
) {
    StringBuilder prompt = new StringBuilder();
    
    prompt.append('Context-Aware Document Generation Request:\n\n');
    
    // Add template information
    prompt.append('Template Structure:\n');
    prompt.append(template.Template_Content__c).append('\n\n');
    
    // Add contextual insights
    prompt.append('Contextual Information from Document Analysis:\n');
    prompt.append('- Common Themes: ').append(String.join(contextAnalysis.commonThemes, ', ')).append('\n');
    prompt.append('- Key Entities: ');
    
    List<String> topEntities = getTopEntities(contextAnalysis.entityFrequency, 10);
    prompt.append(String.join(topEntities, ', ')).append('\n');
    
    prompt.append('- Contextual Insights:\n');
    for (String insight : contextAnalysis.contextualInsights) {
        prompt.append('  * ').append(insight).append('\n');
    }
    
    // Add generation parameters
    if (generationParameters != null && !generationParameters.isEmpty()) {
        prompt.append('\nGeneration Parameters:\n');
        for (String key : generationParameters.keySet()) {
            prompt.append('- ').append(key).append(': ').append(generationParameters.get(key)).append('\n');
        }
    }
    
    prompt.append('\nInstructions:\n');
    prompt.append('Generate a comprehensive document that:\n');
    prompt.append('1. Follows the provided template structure\n');
    prompt.append('2. Incorporates relevant information from the contextual analysis\n');
    prompt.append('3. Maintains consistency with the identified themes and entities\n');
    prompt.append('4. Provides accurate, well-sourced content based on the analyzed documents\n');
    prompt.append('5. Uses professional language appropriate for the document type\n');
    
    return prompt.toString();
}

private static String processGeneratedContent(String response, DocumentTemplate__c template) {
    try {
        // Parse the AI response
        Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(response);
        String generatedContent = (String) responseData.get('generated_content');
        
        if (String.isBlank(generatedContent)) {
            generatedContent = response; // Fallback to raw response
        }
        
        // Apply template variables if needed
        generatedContent = applyTemplateVariables(generatedContent, template);
        
        return generatedContent;
        
    } catch (Exception e) {
        System.debug('Content processing error: ' + e.getMessage());
        return response; // Return raw response as fallback
    }
}

private static String applyTemplateVariables(String content, DocumentTemplate__c template) {
    if (String.isBlank(template.Template_Variables__c)) {
        return content;
    }
    
    try {
        List<Object> variables = (List<Object>) JSON.deserializeUntyped(template.Template_Variables__c);
        
        for (Object varObj : variables) {
            Map<String, Object> variable = (Map<String, Object>) varObj;
            String varName = (String) variable.get('name');
            String defaultValue = (String) variable.get('defaultValue');
            
            if (String.isNotBlank(defaultValue)) {
                content = content.replace('{{' + varName + '}}', defaultValue);
            }
        }
        
    } catch (Exception e) {
        System.debug('Template variable processing error: ' + e.getMessage());
    }
    
    return content;
}

@AuraEnabled
public static String askContextualQuestion(
    String folderId,
    String question,
    String selectedAIModel
) {
    try {
        // Analyze folder context for the question
        FolderContextAnalysis contextAnalysis = analyzeFolderContext(folderId, selectedAIModel);
        
        // Build question prompt with context
        String prompt = buildQuestionPrompt(question, contextAnalysis);
        
        // Process with AI
        Map<String, Object> parameters = new Map<String, Object>{
            'context' => contextAnalysis,
            'question_type' => 'contextual_query'
        };
        
        String response = AIModelManager.processWithEinstein(selectedAIModel, prompt, parameters);
        
        return response;
        
    } catch (Exception e) {
        throw new AuraHandledException('Question processing failed: ' + e.getMessage());
    }
}

private static String buildQuestionPrompt(String question, FolderContextAnalysis contextAnalysis) {
    StringBuilder prompt = new StringBuilder();
    
    prompt.append('Context-Based Question Answering:\n\n');
    prompt.append('Question: ').append(question).append('\n\n');
    
    prompt.append('Available Context:\n');
    prompt.append('Documents analyzed: ').append(contextAnalysis.documents.size()).append('\n');
    
    // Add document summaries
    prompt.append('Document Contents:\n');
    for (DocumentContext doc : contextAnalysis.documents) {
        prompt.append('- ').append(doc.title).append(': ');
        String summary = doc.content.length() > 500 ? 
            doc.content.substring(0, 500) + '...' : doc.content;
        prompt.append(summary).append('\n');
    }
    
    prompt.append('\nKey Themes: ').append(String.join(contextAnalysis.commonThemes, ', ')).append('\n');
    
    List<String> topEntities = getTopEntities(contextAnalysis.entityFrequency, 10);
    prompt.append('Important Entities: ').append(String.join(topEntities, ', ')).append('\n\n');
    
    prompt.append('Instructions:\n');
    prompt.append('Answer the question based ONLY on the provided document context. ');
    prompt.append('If the answer cannot be found in the documents, state that clearly. ');
    prompt.append('Always cite which document(s) your answer comes from. ');
    prompt.append('Provide specific quotes when relevant.\n');
    
    return prompt.toString();
}
}
