
/**
 * Enhanced Template Engine with Context Awareness
 */
public class ContextAwareTemplateEngine {
    
    /**
     * Generate document using context-aware template processing
     */
    public static String generateContextAwareDocument(
        String templateId, 
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext,
        Map<String, Object> generationParameters
    ) {
        try {
            // Retrieve template
            Document_Template__c template = getTemplate(templateId);
            if (template == null) {
                throw new AuraHandledException('Template not found: ' + templateId);
            }
            
            // Generate context merge fields
            Map<String, Object> contextMergeFields = ContextAwareGenerationSupport.generateContextMergeFields(
                folderContext, 
                aggregateEntityFrequencies(folderContext),
                (String)generationParameters.get('aiModel')
            );
            
            // Combine with user parameters
            Map<String, Object> allMergeFields = new Map<String, Object>();
            allMergeFields.putAll(contextMergeFields);
            allMergeFields.putAll(generationParameters);
            
            // Process template with AI enhancement
            String processedContent = processTemplateWithAI(
                template.Template_Content__c,
                allMergeFields,
                folderContext
            );
            
            // Apply post-processing rules
            processedContent = applyPostProcessingRules(processedContent, template);
            
            // Log generation activity
            logDocumentGeneration(templateId, folderContext.folderId, generationParameters);
            
            return processedContent;
            
        } catch (Exception e) {
            System.debug('Error generating context-aware document: ' + e.getMessage());
            throw new AuraHandledException('Document generation failed: ' + e.getMessage());
        }
    }
    
    // /** version v1
    //  * Generate document using context-aware template processing (same method👆)
    //  */
    // public static String generateContextAwareDocument(String templateId,ContextAwareDocumentEngine.FolderContextAnalysis folderContext,Map<String, Object> generationParameters) {
    //     try {
    //         // Get template configuration
    //         Document_Template__c template = [
    //             SELECT Id, Name, Template_Content__c, Template_Type__c, 
    //                    AI_Instructions__c, Merge_Tags__c, Context_Rules__c
    //             FROM Document_Template__c 
    //             WHERE Id = :templateId 
    //             LIMIT 1
    //         ];
            
    //         // Parse template for dynamic sections
    //         TemplateStructure templateStructure = parseTemplate(template.Template_Content__c);
            
    //         // Process each section with contextual intelligence
    //         String processedContent = processTemplateWithContext(
    //             templateStructure, 
    //             folderContext, 
    //             generationParameters
    //         );
            
    //         // Apply post-processing enhancements
    //         String finalContent = applyContextualEnhancements(processedContent, folderContext);
            
    //         return finalContent;
            
    //     } catch (Exception e) {
    //         throw new AuraHandledException('Template processing failed: ' + e.getMessage());
    //     }
    // }
    /**
     * Process template with AI enhancement
     */
    private static String processTemplateWithAI(
        String templateContent,
        Map<String, Object> mergeFields,
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext
    ) {
        String processedContent = templateContent;
        
        // Replace standard merge fields
        for (String fieldName : mergeFields.keySet()) {
            Object fieldValue = mergeFields.get(fieldName);
            String mergeTag = '{!' + fieldName + '}';
            String replacementValue = fieldValue != null ? String.valueOf(fieldValue) : '';
            processedContent = processedContent.replace(mergeTag, replacementValue);
        }
        
        // Process AI-enhanced sections
        processedContent = processAIEnhancedSections(processedContent, folderContext, mergeFields);
        
        // Apply contextual intelligence
        processedContent = applyContextualIntelligence(processedContent, folderContext);
        
        return processedContent;
    }
    
    /**
     * Process AI-enhanced template sections
     */
    private static String processAIEnhancedSections(
        String content,
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext,
        Map<String, Object> mergeFields
    ) {
        // Pattern for AI sections: {!AI:SECTION_TYPE:PARAMETERS}
        Pattern aiSectionPattern = Pattern.compile('\\{!AI:([^:]+):([^}]+)\\}');
        Matcher matcher = aiSectionPattern.matcher(content);
        
        while (matcher.find()) {
            String sectionType = matcher.group(1);
            String parameters = matcher.group(2);
            String aiGeneratedContent = generateAISection(sectionType, parameters, folderContext, mergeFields);
            content = content.replace(matcher.group(0), aiGeneratedContent);
        }
        
        return content;
    }
    
    /**
     * Generate AI-powered content sections
     */
    private static String generateAISection(
        String sectionType,
        String parameters,
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext,
        Map<String, Object> mergeFields
    ) {
        String generatedContent = '';
        
        try {
            switch on sectionType.toUpperCase() {
                when 'SUMMARY' {
                    generatedContent = generateContextualSummary(folderContext, parameters);
                }
                when 'RECOMMENDATIONS' {
                    generatedContent = generateRecommendations(folderContext, parameters);
                }
                when 'ANALYSIS' {
                    generatedContent = generateAnalysisSection(folderContext, parameters);
                }
                when 'INSIGHTS' {
                    generatedContent = generateInsights(folderContext, parameters);
                }
                when 'CUSTOM' {
                    generatedContent = generateCustomSection(folderContext, parameters, mergeFields);
                }
                when else {
                    generatedContent = '[AI Section: ' + sectionType + ' - Not Implemented]';
                }
            }
        } catch (Exception e) {
            System.debug('Error generating AI section: ' + e.getMessage());
            generatedContent = '[AI Section Error: ' + e.getMessage() + ']';
        }
        
        return generatedContent;
    }
    
    /**
     * Generate contextual summary based on folder analysis
     */
    private static String generateContextualSummary(
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext,
        String parameters
    ) {
        StringBuilder summary = new StringBuilder();
        
        summary.append('## Contextual Summary\n\n');
        summary.append('Based on analysis of ' + folderContext.documents.size() + ' documents, ');
        
        if (folderContext.commonThemes != null && !folderContext.commonThemes.isEmpty()) {
            summary.append('the primary themes identified are: ');
            summary.append(String.join(folderContext.commonThemes, ', '));
            summary.append('. ');
        }
        
        if (folderContext.contextSummary != null) {
            summary.append('\n\n');
            summary.append(folderContext.contextSummary);
        }
        
        return summary.toString();
    }
    
    /**
     * Generate recommendations based on context
     */
    private static String generateRecommendations(
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext,
        String parameters
    ) {
        StringBuilder recommendations = new StringBuilder();
        recommendations.append('## Recommendations\n\n');
        
        // Analyze document patterns and suggest improvements
        Map<String, Integer> documentTypes = new Map<String, Integer>();
        for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
            String docType = doc.documentType != null ? doc.documentType : 'UNKNOWN';
            documentTypes.put(docType, documentTypes.containsKey(docType) ? documentTypes.get(docType) + 1 : 1);
        }
        
        recommendations.append('### Document Organization\n');
        recommendations.append('- Total documents analyzed: ' + folderContext.documents.size() + '\n');
        
        for (String docType : documentTypes.keySet()) {
            recommendations.append('- ' + docType + ': ' + documentTypes.get(docType) + ' documents\n');
        }
        
        // Add context-specific recommendations
        if (folderContext.commonThemes != null && folderContext.commonThemes.size() > 3) {
            recommendations.append('\n### Theme Diversity\n');
            recommendations.append('High theme diversity detected. Consider organizing content by topic areas.\n');
        }
        
        return recommendations.toString();
    }
    
    /**
     * Generate analysis section
     */
    private static String generateAnalysisSection(
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext,
        String parameters
    ) {
        StringBuilder analysis = new StringBuilder();
        analysis.append('## Document Analysis\n\n');
        
        // Statistical analysis
        analysis.append('### Statistical Overview\n');
        analysis.append('- Documents analyzed: ' + folderContext.documents.size() + '\n');
        analysis.append('- Analysis completed: ' + DateTime.now().format() + '\n');
        
        if (folderContext.crossDocumentRelations != null) {
            analysis.append('- Cross-document relationships identified\n');
        }
        
        // Content analysis
        if (folderContext.commonThemes != null && !folderContext.commonThemes.isEmpty()) {
            analysis.append('\n### Content Themes\n');
            for (Integer i = 0; i < Math.min(folderContext.commonThemes.size(), 5); i++) {
                analysis.append('- ' + folderContext.commonThemes[i] + '\n');
            }
        }
        
        return analysis.toString();
    }
    
    /**
     * Generate insights section
     */
    private static String generateInsights(
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext,
        String parameters
    ) {
        StringBuilder insights = new StringBuilder();
        insights.append('## Key Insights\n\n');
        
        // Pattern detection
        Map<String, Object> patterns = detectDocumentPatterns(folderContext);
        
        if (patterns.containsKey('documentFrequency')) {
            insights.append('### Document Activity Patterns\n');
            insights.append('Document creation patterns suggest ' + patterns.get('documentFrequency') + '\n\n');
        }
        
        if (patterns.containsKey('contentComplexity')) {
            insights.append('### Content Complexity\n');
            insights.append('Average content complexity: ' + patterns.get('contentComplexity') + '\n\n');
        }
        
        // Contextual insights
        if (folderContext.suggestedTemplates != null && !folderContext.suggestedTemplates.isEmpty()) {
            insights.append('### Template Recommendations\n');
            insights.append('Based on content analysis, the following templates are recommended:\n');
            for (String template : folderContext.suggestedTemplates) {
                insights.append('- ' + template + '\n');
            }
        }
        
        return insights.toString();
    }
    
    /**
     * Generate custom AI section
     */
    private static String generateCustomSection(
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext,
        String parameters,
        Map<String, Object> mergeFields
    ) {
        // Parse parameters for custom AI generation
        Map<String, String> paramMap = parseParameters(parameters);
        String prompt = paramMap.get('prompt');
        String format = paramMap.get('format');
        
        if (String.isBlank(prompt)) {
            return '[Custom AI Section: No prompt specified]';
        }
        
        // Generate custom content based on prompt and context
        return generateCustomAIContent(prompt, folderContext, format);
    }
    
    /**
     * Apply contextual intelligence to processed content
     */
    private static String applyContextualIntelligence(
        String content,
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext
    ) {
        // Apply intelligent formatting based on context
        content = improveContentStructure(content, folderContext);
        
        // Add contextual cross-references
        content = addContextualReferences(content, folderContext);
        
        // Optimize content flow
        content = optimizeContentFlow(content);
        
        return content;
    }
    
    /**
     * Utility methods for template processing
     */
    private static Document_Template__c getTemplate(String templateId) {
        try {
            return [
                SELECT Id, Name, Template_Content__c, Template_Type__c, 
                       Processing_Rules__c, Is_Active__c
                FROM Document_Template__c 
                WHERE Id = :templateId AND Is_Active__c = true
                LIMIT 1
            ];
        } catch (Exception e) {
            System.debug('Error retrieving template: ' + e.getMessage());
            return null;
        }
    }
    
    private static Map<String, Integer> aggregateEntityFrequencies(
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext
    ) {
        Map<String, Integer> aggregated = new Map<String, Integer>();
        
        for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
            if (doc.extractedEntities != null) {
                for (String entity : doc.extractedEntities) {
                    aggregated.put(entity, aggregated.containsKey(entity) ? aggregated.get(entity) + 1 : 1);
                }
            }
        }
        
        return aggregated;
    }
    
    private static String applyPostProcessingRules(String content, Document_Template__c template) {
        // Apply template-specific post-processing rules
        if (template.Processing_Rules__c != null) {
            try {
                Map<String, Object> rules = (Map<String, Object>)JSON.deserializeUntyped(template.Processing_Rules__c);
                // Apply rules based on template configuration
                content = applyFormattingRules(content, rules);
            } catch (Exception e) {
                System.debug('Error applying post-processing rules: ' + e.getMessage());
            }
        }
        
        return content;
    }
    
    private static String applyFormattingRules(String content, Map<String, Object> rules) {
        // Implementation for applying formatting rules
        return content;
    }
    
    private static void logDocumentGeneration(
        String templateId, 
        String folderId, 
        Map<String, Object> parameters
    ) {
        try {
            Document_Generation_Log__c log = new Document_Generation_Log__c();
            log.Template_Id__c = templateId;
            log.Folder_Id__c = folderId;
            log.Generation_Parameters__c = JSON.serialize(parameters);
            log.Generation_Timestamp__c = DateTime.now();
            log.User_Id__c = UserInfo.getUserId();
            
            insert log;
        } catch (Exception e) {
            System.debug('Error logging document generation: ' + e.getMessage());
        }
    }
    
    
private static Map<String, Object> detectDocumentPatterns(
    ContextAwareDocumentEngine.FolderContextAnalysis folderContext
) {
    Map<String, Object> patterns = new Map<String, Object>();
    
    try {
        // Document frequency patterns
        patterns.put('documentFrequency', analyzeDocumentFrequency(folderContext));
        
        // Content complexity patterns
        patterns.put('contentComplexity', analyzeContentComplexity(folderContext));
        
        // Temporal patterns
        patterns.put('temporalPatterns', analyzeTemporalPatterns(folderContext));
        
        // Document type clustering
        patterns.put('typeDistribution', analyzeDocumentTypeDistribution(folderContext));
        
        // Content similarity patterns
        patterns.put('similarityMatrix', analyzeSimilarityPatterns(folderContext));
        
        // Entity relationship patterns
        patterns.put('entityRelationships', analyzeEntityRelationships(folderContext));
        
        // Document hierarchy patterns
        patterns.put('hierarchyPatterns', analyzeHierarchyPatterns(folderContext));
        
        // Language and tone patterns
        patterns.put('languagePatterns', analyzeLanguagePatterns(folderContext));
        
        // Compliance patterns
        patterns.put('compliancePatterns', analyzeCompliancePatterns(folderContext));
        
        // Usage patterns
        patterns.put('usagePatterns', analyzeUsagePatterns(folderContext));
        
    } catch (Exception e) {
        System.debug('Error detecting document patterns: ' + e.getMessage());
        patterns.put('error', e.getMessage());
    }
    
    return patterns;
}

/**
 * Analyze document frequency patterns
 */
private static Map<String, Object> analyzeDocumentFrequency(
    ContextAwareDocumentEngine.FolderContextAnalysis folderContext
) {
    Map<String, Object> frequencyAnalysis = new Map<String, Object>();
    
    try {
        // Analyze creation date patterns
        Map<String, Integer> monthlyDistribution = new Map<String, Integer>();
        Map<String, Integer> weeklyDistribution = new Map<String, Integer>();
        Map<String, Integer> dailyDistribution = new Map<String, Integer>();
        
        for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
            if (doc.metadata != null && doc.metadata.containsKey('createdDate')) {
                DateTime createdDate = (DateTime)doc.metadata.get('createdDate');
                
                // Monthly pattern
                String monthKey = createdDate.format('yyyy-MM');
                monthlyDistribution.put(monthKey, 
                    monthlyDistribution.containsKey(monthKey) ? 
                    monthlyDistribution.get(monthKey) + 1 : 1);
                
                // Weekly pattern
                String weekKey = 'Week-' + String.valueOf(createdDate.format('w'));
                weeklyDistribution.put(weekKey, 
                    weeklyDistribution.containsKey(weekKey) ? 
                    weeklyDistribution.get(weekKey) + 1 : 1);
                
                // Daily pattern
                String dayKey = createdDate.format('EEEE');
                dailyDistribution.put(dayKey, 
                    dailyDistribution.containsKey(dayKey) ? 
                    dailyDistribution.get(dayKey) + 1 : 1);
            }
        }
        
        frequencyAnalysis.put('monthlyDistribution', monthlyDistribution);
        frequencyAnalysis.put('weeklyDistribution', weeklyDistribution);
        frequencyAnalysis.put('dailyDistribution', dailyDistribution);
        
        // Calculate frequency trends
        frequencyAnalysis.put('trend', calculateFrequencyTrend(monthlyDistribution));
        
    } catch (Exception e) {
        System.debug('Error analyzing document frequency: ' + e.getMessage());
        frequencyAnalysis.put('error', e.getMessage());
    }
    
    return frequencyAnalysis;
}

/**
 * Analyze content complexity patterns
 */
private static Map<String, Object> analyzeContentComplexity(
    ContextAwareDocumentEngine.FolderContextAnalysis folderContext
) {
    Map<String, Object> complexityAnalysis = new Map<String, Object>();
    
    try {
        List<Decimal> complexityScores = new List<Decimal>();
        Map<String, Decimal> typeComplexity = new Map<String, Decimal>();
        
        for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
            Decimal docComplexity = calculateDocumentComplexity(doc);
            complexityScores.add(docComplexity);
            
            String docType = doc.documentType != null ? doc.documentType : 'UNKNOWN';
            if (typeComplexity.containsKey(docType)) {
                typeComplexity.put(docType, (typeComplexity.get(docType) + docComplexity) / 2);
            } else {
                typeComplexity.put(docType, docComplexity);
            }
        }
        
        // Calculate statistics
        complexityAnalysis.put('averageComplexity', calculateAverage(complexityScores));
        complexityAnalysis.put('medianComplexity', calculateMedian(complexityScores));
        complexityAnalysis.put('complexityRange', calculateRange(complexityScores));
        complexityAnalysis.put('typeComplexity', typeComplexity);
        complexityAnalysis.put('complexityDistribution', categorizeComplexity(complexityScores));
        
    } catch (Exception e) {
        System.debug('Error analyzing content complexity: ' + e.getMessage());
        complexityAnalysis.put('error', e.getMessage());
    }
    
    return complexityAnalysis;
}

/**
 * Analyze temporal patterns in document creation and modification
 */
private static Map<String, Object> analyzeTemporalPatterns(
    ContextAwareDocumentEngine.FolderContextAnalysis folderContext
) {
    Map<String, Object> temporalAnalysis = new Map<String, Object>();
    
    try {
        List<DateTime> creationTimes = new List<DateTime>();
        List<DateTime> modificationTimes = new List<DateTime>();
        
        for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
            if (doc.metadata != null) {
                if (doc.metadata.containsKey('createdDate')) {
                    creationTimes.add((DateTime)doc.metadata.get('createdDate'));
                }
                if (doc.metadata.containsKey('lastModifiedDate')) {
                    modificationTimes.add((DateTime)doc.metadata.get('lastModifiedDate'));
                }
            }
        }
        
        // Analyze creation patterns
        temporalAnalysis.put('creationTimespan', calculateTimespan(creationTimes));
        temporalAnalysis.put('creationVelocity', calculateCreationVelocity(creationTimes));
        temporalAnalysis.put('peakCreationPeriods', identifyPeakPeriods(creationTimes));
        
        // Analyze modification patterns
        temporalAnalysis.put('modificationFrequency', calculateModificationFrequency(modificationTimes));
        temporalAnalysis.put('maintenancePattern', analyzeMaintenancePattern(creationTimes, modificationTimes));
        
        // Document lifecycle analysis
        temporalAnalysis.put('averageDocumentAge', calculateAverageAge(creationTimes));
        temporalAnalysis.put('lifecycleStages', categorizeDocumentsByAge(creationTimes));
        
    } catch (Exception e) {
        System.debug('Error analyzing temporal patterns: ' + e.getMessage());
        temporalAnalysis.put('error', e.getMessage());
    }
    
    return temporalAnalysis;
}

/**
 * Analyze document type distribution patterns
 */
private static Map<String, Object> analyzeDocumentTypeDistribution(
    ContextAwareDocumentEngine.FolderContextAnalysis folderContext
) {
    Map<String, Object> distributionAnalysis = new Map<String, Object>();
    
    try {
        Map<String, Integer> typeCount = new Map<String, Integer>();
        Map<String, List<String>> typeDocuments = new Map<String, List<String>>();
        Map<String, Decimal> typeSize = new Map<String, Decimal>();
        
        for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
            String docType = doc.documentType != null ? doc.documentType : 'UNKNOWN';
            
            // Count by type
            typeCount.put(docType, typeCount.containsKey(docType) ? typeCount.get(docType) + 1 : 1);
            
            // Group documents by type
            if (!typeDocuments.containsKey(docType)) {
                typeDocuments.put(docType, new List<String>());
            }
            typeDocuments.get(docType).add(doc.documentId);
            
            // Track size by type
            if (doc.metadata != null && doc.metadata.containsKey('contentLength')) {
                Decimal contentLength = (Decimal)doc.metadata.get('contentLength');
                typeSize.put(docType, typeSize.containsKey(docType) ? 
                    (typeSize.get(docType) + contentLength) / 2 : contentLength);
            }
        }
        
        distributionAnalysis.put('typeCount', typeCount);
        distributionAnalysis.put('typeDocuments', typeDocuments);
        distributionAnalysis.put('averageTypeSize', typeSize);
        distributionAnalysis.put('dominantType', findDominantType(typeCount));
        distributionAnalysis.put('diversityIndex', calculateTypeDiversity(typeCount));
        
    } catch (Exception e) {
        System.debug('Error analyzing type distribution: ' + e.getMessage());
        distributionAnalysis.put('error', e.getMessage());
    }
    
    return distributionAnalysis;
}

/**
 * Analyze content similarity patterns between documents
 */
private static Map<String, Object> analyzeSimilarityPatterns(
    ContextAwareDocumentEngine.FolderContextAnalysis folderContext
) {
    Map<String, Object> similarityAnalysis = new Map<String, Object>();
    
    try {
        Map<String, Map<String, Decimal>> similarityMatrix = new Map<String, Map<String, Decimal>>();
        List<Map<String, Object>> similarityPairs = new List<Map<String, Object>>();
        Map<String, List<String>> clusters = new Map<String, List<String>>();
        
        // Calculate pairwise similarities
        for (Integer i = 0; i < folderContext.documents.size(); i++) {
            ContextAwareDocumentEngine.DocumentContext doc1 = folderContext.documents[i];
            if (!similarityMatrix.containsKey(doc1.documentId)) {
                similarityMatrix.put(doc1.documentId, new Map<String, Decimal>());
            }
            
            for (Integer j = i + 1; j < folderContext.documents.size(); j++) {
                ContextAwareDocumentEngine.DocumentContext doc2 = folderContext.documents[j];
                
                Decimal similarity = calculateDocumentSimilarity(doc1, doc2);
                similarityMatrix.get(doc1.documentId).put(doc2.documentId, similarity);
                
                // Track high similarity pairs
                if (similarity > 0.7) {
                    Map<String, Object> pair = new Map<String, Object>();
                    pair.put('doc1', doc1.documentId);
                    pair.put('doc2', doc2.documentId);
                    pair.put('similarity', similarity);
                    similarityPairs.add(pair);
                }
            }
        }
        
        // Identify document clusters
        clusters = identifyDocumentClusters(folderContext.documents, 0.6);
        
        similarityAnalysis.put('similarityMatrix', similarityMatrix);
        similarityAnalysis.put('highSimilarityPairs', similarityPairs);
        similarityAnalysis.put('documentClusters', clusters);
        similarityAnalysis.put('averageSimilarity', calculateAverageSimilarity(similarityMatrix));
        
    } catch (Exception e) {
        System.debug('Error analyzing similarity patterns: ' + e.getMessage());
        similarityAnalysis.put('error', e.getMessage());
    }
    
    return similarityAnalysis;
}

/**
 * Analyze entity relationship patterns across documents
 */
private static Map<String, Object> analyzeEntityRelationships(
    ContextAwareDocumentEngine.FolderContextAnalysis folderContext
) {
    Map<String, Object> entityAnalysis = new Map<String, Object>();
    
    try {
        Map<String, Integer> entityFrequency = new Map<String, Integer>();
        Map<String, Set<String>> entityCoOccurrence = new Map<String, Set<String>>();
        Map<String, List<String>> entityDocuments = new Map<String, List<String>>();
        
        // Analyze entity patterns
        for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
            if (doc.extractedEntities != null) {
                for (String entity : doc.extractedEntities) {
                    // Track entity frequency
                    entityFrequency.put(entity, 
                        entityFrequency.containsKey(entity) ? 
                        entityFrequency.get(entity) + 1 : 1);
                    
                    // Track entity-document relationships
                    if (!entityDocuments.containsKey(entity)) {
                        entityDocuments.put(entity, new List<String>());
                    }
                    entityDocuments.get(entity).add(doc.documentId);
                    
                    // Track entity co-occurrence
                    if (!entityCoOccurrence.containsKey(entity)) {
                        entityCoOccurrence.put(entity, new Set<String>());
                    }
                    for (String coEntity : doc.extractedEntities) {
                        if (coEntity != entity) {
                            entityCoOccurrence.get(entity).add(coEntity);
                        }
                    }
                }
            }
        }
        
        entityAnalysis.put('entityFrequency', entityFrequency);
        entityAnalysis.put('entityCoOccurrence', convertSetMapToListMap(entityCoOccurrence));
        entityAnalysis.put('entityDocuments', entityDocuments);
        entityAnalysis.put('centralEntities', identifyCentralEntities(entityFrequency, entityCoOccurrence));
        entityAnalysis.put('entityClusters', clusterEntitiesByCoOccurrence(entityCoOccurrence));
        
    } catch (Exception e) {
        System.debug('Error analyzing entity relationships: ' + e.getMessage());
        entityAnalysis.put('error', e.getMessage());
    }
    
    return entityAnalysis;
}

/**
 * Analyze document hierarchy and structure patterns
 */
private static Map<String, Object> analyzeHierarchyPatterns(
    ContextAwareDocumentEngine.FolderContextAnalysis folderContext
) {
    Map<String, Object> hierarchyAnalysis = new Map<String, Object>();
    
    try {
        Map<String, List<String>> parentChildRelations = new Map<String, List<String>>();
        Map<String, Integer> documentLevels = new Map<String, Integer>();
        Map<String, String> documentCategories = new Map<String, String>();
        
        for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
            // Analyze document structure based on content patterns
            Integer structuralLevel = analyzeDocumentStructuralLevel(doc);
            documentLevels.put(doc.documentId, structuralLevel);
            
            // Categorize documents based on naming patterns
            String category = categorizeDocumentByName(doc);
            documentCategories.put(doc.documentId, category);
            
            // Identify parent-child relationships
            
    List<String> relatedDocs = findRelatedDocuments(doc, folderContext);
                    if (!relatedDocs.isEmpty()) {
                        parentChildRelations.put(doc.documentId, relatedDocs);
                    }
                }

            hierarchyAnalysis.put('parentChildRelations', parentChildRelations);
            hierarchyAnalysis.put('documentLevels', documentLevels);
            hierarchyAnalysis.put('documentCategories', documentCategories);
            hierarchyAnalysis.put('hierarchyDepth', calculateHierarchyDepth(parentChildRelations));
            hierarchyAnalysis.put('orphanDocuments', identifyOrphanDocuments(folderContext.documents, parentChildRelations));

        } catch (Exception e) {
            System.debug('Error analyzing hierarchy patterns: ' + e.getMessage());
            hierarchyAnalysis.put('error', e.getMessage());
        }

        return hierarchyAnalysis;
    }

    /**
     * Find related documents based on content, naming patterns, and metadata
     */
    private static List<String> findRelatedDocuments(
        ContextAwareDocumentEngine.DocumentContext doc, 
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext
    ) {
        List<String> relatedDocs = new List<String>();
        
        try {
            // Find documents with similar content
            List<String> contentRelated = findContentRelatedDocuments(doc, folderContext);
            relatedDocs.addAll(contentRelated);
            
            // Find documents with naming pattern relationships
            List<String> nameRelated = findNamePatternRelatedDocuments(doc, folderContext);
            relatedDocs.addAll(nameRelated);
            
            // Find documents with metadata relationships
            List<String> metadataRelated = findMetadataRelatedDocuments(doc, folderContext);
            relatedDocs.addAll(metadataRelated);
            
            // Find documents with entity overlap
            List<String> entityRelated = findEntityRelatedDocuments(doc, folderContext);
            relatedDocs.addAll(entityRelated);
            
            // Find documents with temporal relationships
            List<String> temporalRelated = findTemporallyRelatedDocuments(doc, folderContext);
            relatedDocs.addAll(temporalRelated);
            
            // Remove duplicates and self-references
            Set<String> uniqueRelated = new Set<String>(relatedDocs);
            uniqueRelated.remove(doc.documentId);
            relatedDocs = new List<String>(uniqueRelated);
            
        } catch (Exception e) {
            System.debug('Error finding related documents for ' + doc.documentId + ': ' + e.getMessage());
        }
        
        return relatedDocs;
    }

    /**
     * Find documents related by content similarity
     */
    private static List<String> findContentRelatedDocuments(
        ContextAwareDocumentEngine.DocumentContext targetDoc,
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext
    ) {
        List<String> contentRelated = new List<String>();
        
        try {
            for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
                if (doc.documentId != targetDoc.documentId) {
                    Decimal similarity = calculateDocumentSimilarity(targetDoc, doc);
                    if (similarity > 0.5) { // 50% similarity threshold
                        contentRelated.add(doc.documentId);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error finding content related documents: ' + e.getMessage());
        }
        
        return contentRelated;
    }

    /**
     * Find documents related by naming patterns
     */
    private static List<String> findNamePatternRelatedDocuments(
        ContextAwareDocumentEngine.DocumentContext targetDoc,
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext
    ) {
        List<String> nameRelated = new List<String>();
        
        try {
            String targetName = getDocumentName(targetDoc);
            if (String.isBlank(targetName)) return nameRelated;
            
            // Extract base name patterns
            String baseName = extractBaseName(targetName);
            Pattern versionPattern = Pattern.compile('(?i)v\\d+|version\\s*\\d+|rev\\s*\\d+');
            Pattern datePattern = Pattern.compile('\\d{4}-\\d{2}-\\d{2}|\\d{2}/\\d{2}/\\d{4}');
            
            for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
                if (doc.documentId != targetDoc.documentId) {
                    String docName = getDocumentName(doc);
                    if (String.isNotBlank(docName)) {
                        // Check for base name similarity
                        if (docName.containsIgnoreCase(baseName) || baseName.containsIgnoreCase(extractBaseName(docName))) {
                            nameRelated.add(doc.documentId);
                        }
                        
                        // Check for version relationships
                        if (versionPattern.matcher(targetName).find() && versionPattern.matcher(docName).find()) {
                            String targetBase = versionPattern.matcher(targetName).replaceAll('').trim();
                            String docBase = versionPattern.matcher(docName).replaceAll('').trim();
                            if (targetBase.equalsIgnoreCase(docBase)) {
                                nameRelated.add(doc.documentId);
                            }
                        }
                        
                        // Check for date-based relationships
                        if (datePattern.matcher(targetName).find() && datePattern.matcher(docName).find()) {
                            String targetDateless = datePattern.matcher(targetName).replaceAll('').trim();
                            String docDateless = datePattern.matcher(docName).replaceAll('').trim();
                            if (targetDateless.equalsIgnoreCase(docDateless)) {
                                nameRelated.add(doc.documentId);
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error finding name pattern related documents: ' + e.getMessage());
        }
        
        return nameRelated;
    }

    /**
     * Find documents related by metadata attributes
     */
    private static List<String> findMetadataRelatedDocuments(
        ContextAwareDocumentEngine.DocumentContext targetDoc,
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext
    ) {
        List<String> metadataRelated = new List<String>();
        
        try {
            if (targetDoc.metadata == null) return metadataRelated;
            
            for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
                if (doc.documentId != targetDoc.documentId && doc.metadata != null) {
                    Integer matchCount = 0;
                    
                    // Check for common metadata attributes
                    if (bothContainKey(targetDoc.metadata, doc.metadata, 'author') && 
                        targetDoc.metadata.get('author') == doc.metadata.get('author')) {
                        matchCount++;
                    }
                    
                    if (bothContainKey(targetDoc.metadata, doc.metadata, 'project') && 
                        targetDoc.metadata.get('project') == doc.metadata.get('project')) {
                        matchCount++;
                    }
                    
                    if (bothContainKey(targetDoc.metadata, doc.metadata, 'department') && 
                        targetDoc.metadata.get('department') == doc.metadata.get('department')) {
                        matchCount++;
                    }
                    
                    if (bothContainKey(targetDoc.metadata, doc.metadata, 'category') && 
                        targetDoc.metadata.get('category') == doc.metadata.get('category')) {
                        matchCount++;
                    }
                    
                    // Check for tag overlap
                    if (bothContainKey(targetDoc.metadata, doc.metadata, 'tags')) {
                        List<String> targetTags = (List<String>)targetDoc.metadata.get('tags');
                        List<String> docTags = (List<String>)doc.metadata.get('tags');
                        if (targetTags != null && docTags != null) {
                            Set<String> commonTags = new Set<String>(targetTags);
                            commonTags.retainAll(new Set<String>(docTags));
                            if (!commonTags.isEmpty()) {
                                matchCount += commonTags.size();
                            }
                        }
                    }
                    
                    // If significant metadata overlap, consider related
                    if (matchCount >= 2) {
                        metadataRelated.add(doc.documentId);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error finding metadata related documents: ' + e.getMessage());
        }
        
        return metadataRelated;
    }

    /**
     * Find documents related by entity overlap
     */
    private static List<String> findEntityRelatedDocuments(
        ContextAwareDocumentEngine.DocumentContext targetDoc,
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext
    ) {
        List<String> entityRelated = new List<String>();
        
        try {
            if (targetDoc.extractedEntities == null || targetDoc.extractedEntities.isEmpty()) {
                return entityRelated;
            }
            
            Set<String> targetEntities = new Set<String>(targetDoc.extractedEntities);
            
            for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
                if (doc.documentId != targetDoc.documentId && 
                    doc.extractedEntities != null && !doc.extractedEntities.isEmpty()) {
                    
                    Set<String> docEntities = new Set<String>(doc.extractedEntities);
                    Set<String> commonEntities = new Set<String>(targetEntities);
                    commonEntities.retainAll(docEntities);
                    
                    // Calculate entity overlap percentage
                    Decimal overlapPercentage = (Decimal)commonEntities.size() / 
                                              Math.max(targetEntities.size(), docEntities.size());
                    
                    if (overlapPercentage > 0.3) { // 30% entity overlap threshold
                        entityRelated.add(doc.documentId);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error finding entity related documents: ' + e.getMessage());
        }
        
        return entityRelated;
    }

    /**
     * Find documents related by temporal proximity
     */
    private static List<String> findTemporallyRelatedDocuments(
        ContextAwareDocumentEngine.DocumentContext targetDoc,
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext
    ) {
        List<String> temporalRelated = new List<String>();
        
        try {
            if (targetDoc.metadata == null || !targetDoc.metadata.containsKey('createdDate')) {
                return temporalRelated;
            }
            
            DateTime targetDate = (DateTime)targetDoc.metadata.get('createdDate');
            Integer proximityDays = 7; // 7-day window
            
            for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
                if (doc.documentId != targetDoc.documentId && 
                    doc.metadata != null && doc.metadata.containsKey('createdDate')) {
                    
                    DateTime docDate = (DateTime)doc.metadata.get('createdDate');
                    Long daysDifference = Math.abs(targetDate.date().daysBetween(docDate.date()));
                    
                    if (daysDifference <= proximityDays) {
                        temporalRelated.add(doc.documentId);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error finding temporally related documents: ' + e.getMessage());
        }
        
        return temporalRelated;
    }

    /**
     * Calculate similarity between two documents
     */
    private static Decimal calculateDocumentSimilarity(
        ContextAwareDocumentEngine.DocumentContext doc1,
        ContextAwareDocumentEngine.DocumentContext doc2
    ) {
        try {
            Decimal similarity = 0.0;
            Integer factors = 0;
            
            // Content-based similarity
            if (doc1.summary != null && doc2.summary != null) {
                similarity += calculateTextSimilarity(doc1.summary, doc2.summary) * 0.4;
                factors++;
            }
            
            // Entity overlap similarity
            if (doc1.extractedEntities != null && doc2.extractedEntities != null && 
                !doc1.extractedEntities.isEmpty() && !doc2.extractedEntities.isEmpty()) {
                Set<String> entities1 = new Set<String>(doc1.extractedEntities);
                Set<String> entities2 = new Set<String>(doc2.extractedEntities);
                Set<String> intersection = new Set<String>(entities1);
                intersection.retainAll(entities2);
                
                Decimal entitySimilarity = (Decimal)intersection.size() / 
                                         Math.max(entities1.size(), entities2.size());
                similarity += entitySimilarity * 0.3;
                factors++;
            }
            
            // Document type similarity
            if (doc1.documentType != null && doc2.documentType != null) {
                similarity += (doc1.documentType.equals(doc2.documentType) ? 1.0 : 0.0) * 0.2;
                factors++;
            }
            
            // Theme overlap similarity
            if (doc1.themes != null && doc2.themes != null && 
                !doc1.themes.isEmpty() && !doc2.themes.isEmpty()) {
                Set<String> themes1 = new Set<String>(doc1.themes);
                Set<String> themes2 = new Set<String>(doc2.themes);
                Set<String> themeIntersection = new Set<String>(themes1);
                themeIntersection.retainAll(themes2);
                
                Decimal themeSimilarity = (Decimal)themeIntersection.size() / 
                                        Math.max(themes1.size(), themes2.size());
                similarity += themeSimilarity * 0.1;
                factors++;
            }
            
            return factors > 0 ? similarity / factors : 0.0;
            
        } catch (Exception e) {
            System.debug('Error calculating document similarity: ' + e.getMessage());
            return 0.0;
        }
    }

    /**
     * Calculate text similarity using basic string comparison
     */
    private static Decimal calculateTextSimilarity(String text1, String text2) {
        try {
            if (String.isBlank(text1) || String.isBlank(text2)) return 0.0;
            
            // Convert to lowercase and split into words
            List<String> words1 = text1.toLowerCase().split('\\s+');
            List<String> words2 = text2.toLowerCase().split('\\s+');
            
            // Calculate Jaccard similarity
            Set<String> set1 = new Set<String>(words1);
            Set<String> set2 = new Set<String>(words2);
            Set<String> intersection = new Set<String>(set1);
            intersection.retainAll(set2);
            
            Set<String> union = new Set<String>(set1);
            union.addAll(set2);
            
            return union.isEmpty() ? 0.0 : (Decimal)intersection.size() / union.size();
            
        } catch (Exception e) {
            System.debug('Error calculating text similarity: ' + e.getMessage());
            return 0.0;
        }
    }

    /**
     * Extract base name from document name by removing version indicators and extensions
     */
    private static String extractBaseName(String fileName) {
        if (String.isBlank(fileName)) return '';
        
        String baseName = fileName;
        
        
// Remove file extension
if (baseName.contains('.')) {
    baseName = baseName.substring(0, baseName.lastIndexOf('.'));
}

// Remove version patterns
Pattern versionPattern = Pattern.compile('(?i)\\s*[-_\\s]*(v|version|rev|revision)\\s*\\d+.*$');
baseName = versionPattern.matcher(baseName).replaceAll('');

// Remove date patterns
Pattern datePattern = Pattern.compile('(?i)\\s*[-_\\s]*\\d{4}[-_]\\d{2}[-_]\\d{2}.*$');
baseName = datePattern.matcher(baseName).replaceAll('');

// Remove timestamp patterns
Pattern timestampPattern = Pattern.compile('(?i)\\s*[-_\\s]*\\d{2}[-_]\\d{2}[-_]\\d{4}.*$');
baseName = timestampPattern.matcher(baseName).replaceAll('');

// Remove copy indicators
Pattern copyPattern = Pattern.compile('(?i)\\s*[-_\\s]*(copy|duplicate|backup)\\s*\\d*$');
baseName = copyPattern.matcher(baseName).replaceAll('');

return baseName.trim();
}

/**
 * Get document name from context
 */
private static String getDocumentName(ContextAwareDocumentEngine.DocumentContext doc) {
    if (doc.metadata != null && doc.metadata.containsKey('title')) {
        return (String)doc.metadata.get('title');
    }
    if (doc.metadata != null && doc.metadata.containsKey('name')) {
        return (String)doc.metadata.get('name');
    }
    return null;
}

/**
 * Check if both maps contain the specified key
 */
private static Boolean bothContainKey(Map<String, Object> map1, Map<String, Object> map2, String key) {
    return map1.containsKey(key) && map2.containsKey(key);
}

/**
 * Analyze language and tone patterns across documents
 */
private static Map<String, Object> analyzeLanguagePatterns(
    ContextAwareDocumentEngine.FolderContextAnalysis folderContext
) {
    Map<String, Object> languageAnalysis = new Map<String, Object>();
    
    try {
        Map<String, Integer> languageDistribution = new Map<String, Integer>();
        Map<String, Integer> toneDistribution = new Map<String, Integer>();
        Map<String, Decimal> readabilityScores = new Map<String, Decimal>();
        Map<String, Integer> formalityLevels = new Map<String, Integer>();
        
        for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
            // Language detection
            String detectedLanguage = detectLanguage(doc);
            languageDistribution.put(detectedLanguage, 
                languageDistribution.containsKey(detectedLanguage) ? 
                languageDistribution.get(detectedLanguage) + 1 : 1);
            
            // Tone analysis
            String documentTone = analyzeTone(doc);
            toneDistribution.put(documentTone,
                toneDistribution.containsKey(documentTone) ?
                toneDistribution.get(documentTone) + 1 : 1);
            
            // Readability analysis
            Decimal readabilityScore = calculateReadabilityScore(doc);
            readabilityScores.put(doc.documentId, readabilityScore);
            
            // Formality analysis
            Integer formalityLevel = analyzeFormalityLevel(doc);
            String formalityCategory = categorizeFormalityLevel(formalityLevel);
            formalityLevels.put(formalityCategory,
                formalityLevels.containsKey(formalityCategory) ?
                formalityLevels.get(formalityCategory) + 1 : 1);
        }
        
        languageAnalysis.put('languageDistribution', languageDistribution);
        languageAnalysis.put('toneDistribution', toneDistribution);
        languageAnalysis.put('averageReadability', calculateAverageReadability(readabilityScores));
        languageAnalysis.put('formalityDistribution', formalityLevels);
        languageAnalysis.put('linguisticDiversity', calculateLinguisticDiversity(languageDistribution));
        
    } catch (Exception e) {
        System.debug('Error analyzing language patterns: ' + e.getMessage());
        languageAnalysis.put('error', e.getMessage());
    }
    
    return languageAnalysis;
}

/**
 * Analyze compliance patterns across documents
 */
private static Map<String, Object> analyzeCompliancePatterns(
    ContextAwareDocumentEngine.FolderContextAnalysis folderContext
) {
    Map<String, Object> complianceAnalysis = new Map<String, Object>();
    
    try {
        Map<String, Integer> complianceFrameworks = new Map<String, Integer>();
        Map<String, Integer> complianceStatuses = new Map<String, Integer>();
        Map<String, List<String>> complianceGaps = new Map<String, List<String>>();
        List<Map<String, Object>> complianceIssues = new List<Map<String, Object>>();
        
        for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
            // Detect compliance frameworks
            List<String> detectedFrameworks = detectComplianceFrameworks(doc);
            for (String framework : detectedFrameworks) {
                complianceFrameworks.put(framework,
                    complianceFrameworks.containsKey(framework) ?
                    complianceFrameworks.get(framework) + 1 : 1);
            }
            
            // Analyze compliance status
            String complianceStatus = analyzeDocumentComplianceStatus(doc);
            complianceStatuses.put(complianceStatus,
                complianceStatuses.containsKey(complianceStatus) ?
                complianceStatuses.get(complianceStatus) + 1 : 1);
            
            // Identify compliance gaps
            List<String> gaps = identifyComplianceGaps(doc);
            if (!gaps.isEmpty()) {
                complianceGaps.put(doc.documentId, gaps);
            }
            
            // Log compliance issues
            List<String> issues = identifyComplianceIssues(doc);
            if (!issues.isEmpty()) {
                Map<String, Object> issueReport = new Map<String, Object>();
                issueReport.put('documentId', doc.documentId);
                issueReport.put('issues', issues);
                issueReport.put('severity', calculateComplianceSeverity(issues));
                complianceIssues.add(issueReport);
            }
        }
        
        complianceAnalysis.put('frameworkDistribution', complianceFrameworks);
        complianceAnalysis.put('statusDistribution', complianceStatuses);
        complianceAnalysis.put('complianceGaps', complianceGaps);
        complianceAnalysis.put('complianceIssues', complianceIssues);
        complianceAnalysis.put('overallComplianceScore', calculateOverallComplianceScore(complianceStatuses));
        
    } catch (Exception e) {
        System.debug('Error analyzing compliance patterns: ' + e.getMessage());
        complianceAnalysis.put('error', e.getMessage());
    }
    
    return complianceAnalysis;
}

/**
 * Analyze document usage patterns
 */
private static Map<String, Object> analyzeUsagePatterns(
    ContextAwareDocumentEngine.FolderContextAnalysis folderContext
) {
    Map<String, Object> usageAnalysis = new Map<String, Object>();
    
    try {
        Map<String, Integer> accessFrequency = new Map<String, Integer>();
        Map<String, DateTime> lastAccessed = new Map<String, DateTime>();
        Map<String, Integer> editFrequency = new Map<String, Integer>();
        Map<String, List<String>> collaborators = new Map<String, List<String>>();
        
        for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
            // Analyze access patterns
            if (doc.metadata != null) {
                if (doc.metadata.containsKey('accessCount')) {
                    Integer accessCount = (Integer)doc.metadata.get('accessCount');
                    String accessCategory = categorizeAccessFrequency(accessCount);
                    accessFrequency.put(accessCategory,
                        accessFrequency.containsKey(accessCategory) ?
                        accessFrequency.get(accessCategory) + 1 : 1);
                }
                
                if (doc.metadata.containsKey('lastAccessedDate')) {
                    lastAccessed.put(doc.documentId, (DateTime)doc.metadata.get('lastAccessedDate'));
                }
                
                if (doc.metadata.containsKey('editCount')) {
                    Integer editCount = (Integer)doc.metadata.get('editCount');
                    String editCategory = categorizeEditFrequency(editCount);
                    editFrequency.put(editCategory,
                        editFrequency.containsKey(editCategory) ?
                        editFrequency.get(editCategory) + 1 : 1);
                }
                
                if (doc.metadata.containsKey('collaborators')) {
                    List<String> docCollaborators = (List<String>)doc.metadata.get('collaborators');
                    if (docCollaborators != null && !docCollaborators.isEmpty()) {
                        collaborators.put(doc.documentId, docCollaborators);
                    }
                }
            }
        }
        
        usageAnalysis.put('accessFrequency', accessFrequency);
        usageAnalysis.put('recentlyAccessed', identifyRecentlyAccessedDocuments(lastAccessed));
        usageAnalysis.put('editFrequency', editFrequency);
        usageAnalysis.put('collaborationNetwork', analyzeCollaborationNetwork(collaborators));
        usageAnalysis.put('inactiveDocuments', identifyInactiveDocuments(lastAccessed));
        
    } catch (Exception e) {
        System.debug('Error analyzing usage patterns: ' + e.getMessage());
        usageAnalysis.put('error', e.getMessage());
    }
    
    return usageAnalysis;
}

/**
 * Helper method to parse parameters from AI section configuration
 */
private static Map<String, String> parseParameters(String parameters) {
    Map<String, String> paramMap = new Map<String, String>();
    
    try {
        if (String.isNotBlank(parameters)) {
            List<String> paramPairs = parameters.split(',');
            for (String pair : paramPairs) {
                if (pair.contains('=')) {
                    List<String> keyValue = pair.split('=', 2);
                    if (keyValue.size() == 2) {
                        paramMap.put(keyValue[0].trim(), keyValue[1].trim());
                    }
                }
            }
        }
    } catch (Exception e) {
        System.debug('Error parsing parameters: ' + e.getMessage());
    }
    
    return paramMap;
}

/**
 * Generate custom AI content based on prompt and context
 */
private static String generateCustomAIContent(
    String prompt, 
    ContextAwareDocumentEngine.FolderContextAnalysis folderContext,
    String format
) {
    StringBuilder customContent = new StringBuilder();
    
    try {
        // Process the prompt with context substitution
        String processedPrompt = processPromptWithContext(prompt, folderContext);
        
        // Generate content based on prompt type
        if (prompt.containsIgnoreCase('summary')) {
            customContent.append(generateContextualSummary(folderContext, format));
        } else if (prompt.containsIgnoreCase('analysis')) {
            customContent.append(generateAnalysisSection(folderContext, format));
        } else if (prompt.containsIgnoreCase('recommendation')) {
            customContent.append(generateRecommendations(folderContext, format));
        } else if (prompt.containsIgnoreCase('insight')) {
            customContent.append(generateInsights(folderContext, format));
        } else {
            // Generic content generation based on prompt
            customContent.append(generateGenericAIContent(processedPrompt, folderContext, format));
        }
        
        // Apply formatting if specified
        if (String.isNotBlank(format)) {
            customContent = new StringBuilder(applyContentFormatting(customContent.toString(), format));
        }
        
    } catch (Exception e) {
        System.debug('Error generating custom AI content: ' + e.getMessage());
        customContent.append('[Custom AI Content Generation Failed: ' + e.getMessage() + ']');
    }
    
    return customContent.toString();
}

/**
 * Process prompt with context substitution
 */
private static String processPromptWithContext(
    String prompt, 
    ContextAwareDocumentEngine.FolderContextAnalysis folderContext
) {
    String processedPrompt = prompt;
    
    try {
        // Replace context variables in the prompt
        processedPrompt = processedPrompt.replace('{DOCUMENT_COUNT}', String.valueOf(folderContext.documents.size()));
        
        if (folderContext.commonThemes != null && !folderContext.commonThemes.isEmpty()) {
            processedPrompt = processedPrompt.replace('{PRIMARY_THEME}', folderContext.commonThemes[0]);
            processedPrompt = processedPrompt.replace('{ALL_THEMES}', String.join(folderContext.commonThemes, ', '));
        }
        
        if (folderContext.contextSummary != null) {
            processedPrompt = processedPrompt.replace('{CONTEXT_SUMMARY}', folderContext.contextSummary);
        }
        
        // Add timestamp
        processedPrompt = processedPrompt.replace('{TIMESTAMP}', DateTime.now().format());
        
    } catch (Exception e) {
        System.debug('Error processing prompt with context: ' + e.getMessage());
    }
    
    return processedPrompt;
}

/**
 * Generate generic AI content based on processed prompt
 */
private static String generateGenericAIContent(
    String processedPrompt,
    ContextAwareDocumentEngine.FolderContextAnalysis folderContext,
    String format
) {
    StringBuilder content = new StringBuilder();
    
    try {
        content.append('## AI-Generated Content\n\n');
        content.append('**Prompt:** ' + processedPrompt + '\n\n');
        
        // Generate content based on available context
        if (folderContext.documents != null && !folderContext.documents.isEmpty()) {
            content.append('### Context Analysis\n');
            content.append('Based on analysis of ' + folderContext.documents.size() + ' documents:\n\n');
            
            if (folderContext.commonThemes != null && !folderContext.commonThemes.isEmpty()) {
                content.append('**Key Themes:**\n');
                for (String theme : folderContext.commonThemes) {
                    content.append('- ' + theme + '\n');
                }
                content.append('\n');
            }
            
            if (folderContext.contextSummary != null) {
                content.append('**Context Summary:**\n');
                content.append(folderContext.contextSummary + '\n\n');
            }
        }
        
        content.append('*This content was generated using AI-powered document analysis.*');
        
    } catch (Exception e) {
        System.debug('Error generating generic AI content: ' + e.getMessage());
        content.append('[Content generation failed: ' + e.getMessage() + ']');
    }
    
    return content.toString();
}

/**
 * Apply content formatting based on specified format
 */
private static String applyContentFormatting(String content, String format) {
    String formattedContent = content;
    
  
try {
    switch on format.toLowerCase() {
        when 'html' {
            formattedContent = convertMarkdownToHTML(content);
        }
        when 'plain' {
            formattedContent = stripMarkdownFormatting(content);
        }
        when 'bullet' {
            formattedContent = convertToBulletPoints(content);
        }
        when 'numbered' {
            formattedContent = convertToNumberedList(content);
        }
        when 'table' {
            formattedContent = convertToTableFormat(content);
        }
        when 'executive' {
            formattedContent = formatAsExecutiveSummary(content);
        }
        when 'technical' {
            formattedContent = formatAsTechnicalDocument(content);
        }
        when 'report' {
            formattedContent = formatAsReport(content);
        }
        when else {
            // Keep original formatting
            formattedContent = content;
        }
    }
} catch (Exception e) {
    System.debug('Error applying content formatting: ' + e.getMessage());
    formattedContent = content; // Fall back to original
}

return formattedContent;
}

/**
 * Convert markdown to HTML
 */
private static String convertMarkdownToHTML(String markdown) {
    String html = markdown;
    
    try {
        // Convert headers
        html = html.replaceAll('(?m)^### (.+)$', '<h3>$1</h3>');
        html = html.replaceAll('(?m)^## (.+)$', '<h2>$1</h2>');
        html = html.replaceAll('(?m)^# (.+)$', '<h1>$1</h1>');
        
        // Convert bold and italic
        html = html.replaceAll('\\*\\*(.+?)\\*\\*', '<strong>$1</strong>');
        html = html.replaceAll('\\*(.+?)\\*', '<em>$1</em>');
        
        // Convert bullet points
        html = html.replaceAll('(?m)^- (.+)$', '<li>$1</li>');
        html = html.replaceAll('(<li>.*</li>)', '<ul>$1</ul>');
        
        // Convert line breaks
        html = html.replaceAll('\n\n', '</p><p>');
        html = '<p>' + html + '</p>';
        
        // Clean up empty paragraphs
        html = html.replaceAll('<p></p>', '');
        
    } catch (Exception e) {
        System.debug('Error converting markdown to HTML: ' + e.getMessage());
    }
    
    return html;
}

/**
 * Strip markdown formatting for plain text
 */
private static String stripMarkdownFormatting(String markdown) {
    String plainText = markdown;
    
    try {
        // Remove headers
        plainText = plainText.replaceAll('(?m)^#+\\s*', '');
        
        // Remove bold and italic
        plainText = plainText.replaceAll('\\*\\*(.+?)\\*\\*', '$1');
        plainText = plainText.replaceAll('\\*(.+?)\\*', '$1');
        
        // Remove bullet points
        plainText = plainText.replaceAll('(?m)^-\\s*', '');
        
        // Clean up extra spaces
        plainText = plainText.replaceAll('\\s+', ' ').trim();
        
    } catch (Exception e) {
        System.debug('Error stripping markdown formatting: ' + e.getMessage());
    }
    
    return plainText;
}

/**
 * Convert content to bullet points format
 */
private static String convertToBulletPoints(String content) {
    StringBuilder bullets = new StringBuilder();
    
    try {
        List<String> lines = content.split('\n');
        Boolean inSection = false;
        String currentSection = '';
        
        for (String line : lines) {
            line = line.trim();
            if (String.isNotBlank(line)) {
                // Check if it's a header
                if (line.startsWith('#')) {
                    if (inSection && String.isNotBlank(currentSection)) {
                        bullets.append('\n');
                    }
                    currentSection = line.replaceAll('^#+\\s*', '');
                    bullets.append('• **' + currentSection + '**\n');
                    inSection = true;
                } else if (!line.startsWith('-') && !line.startsWith('•')) {
                    // Convert regular text to bullet points
                    bullets.append('  - ' + line + '\n');
                } else {
                    // Already a bullet point, just add it
                    bullets.append('  ' + line + '\n');
                }
            }
        }
        
    } catch (Exception e) {
        System.debug('Error converting to bullet points: ' + e.getMessage());
        return content;
    }
    
    return bullets.toString();
}

/**
 * Convert content to numbered list format
 */
private static String convertToNumberedList(String content) {
    StringBuilder numbered = new StringBuilder();
    
    try {
        List<String> lines = content.split('\n');
        Integer counter = 1;
        Boolean inSection = false;
        
        for (String line : lines) {
            line = line.trim();
            if (String.isNotBlank(line)) {
                // Check if it's a header
                if (line.startsWith('#')) {
                    String sectionTitle = line.replaceAll('^#+\\s*', '');
                    numbered.append('\n' + counter + '. **' + sectionTitle + '**\n');
                    counter++;
                    inSection = true;
                } else if (!line.matches('^\\d+\\.\\s*.*')) {
                    // Convert regular text to numbered items
                    if (inSection) {
                        numbered.append('   ' + (counter-1) + '.' + (counter-1) + ' ' + line + '\n');
                    } else {
                        numbered.append(counter + '. ' + line + '\n');
                        counter++;
                    }
                } else {
                    // Already numbered, just add it
                    numbered.append(line + '\n');
                }
            }
        }
        
    } catch (Exception e) {
        System.debug('Error converting to numbered list: ' + e.getMessage());
        return content;
    }
    
    return numbered.toString();
}

/**
 * Convert content to table format
 */
private static String convertToTableFormat(String content) {
    StringBuilder table = new StringBuilder();
    
    try {
        table.append('| Section | Content |\n');
        table.append('|---------|----------|\n');
        
        List<String> lines = content.split('\n');
        String currentSection = 'General';
        StringBuilder currentContent = new StringBuilder();
        
        for (String line : lines) {
            line = line.trim();
            if (String.isNotBlank(line)) {
                if (line.startsWith('#')) {
                    // Save previous section if exists
                    if (currentContent.length() > 0) {
                        table.append('| ' + currentSection + ' | ' + 
                                   currentContent.toString().replace('\n', '<br>') + ' |\n');
                        currentContent = new StringBuilder();
                    }
                    currentSection = line.replaceAll('^#+\\s*', '');
                } else {
                    currentContent.append(line + ' ');
                }
            }
        }
        
        // Add final section
        if (currentContent.length() > 0) {
            table.append('| ' + currentSection + ' | ' + 
                       currentContent.toString().replace('\n', '<br>') + ' |\n');
        }
        
    } catch (Exception e) {
        System.debug('Error converting to table format: ' + e.getMessage());
        return content;
    }
    
    return table.toString();
}

/**
 * Format content as executive summary
 */
private static String formatAsExecutiveSummary(String content) {
    StringBuilder executive = new StringBuilder();
    
    try {
        executive.append('# Executive Summary\n\n');
        executive.append('**Document:** Context-Aware Analysis Report\n');
        executive.append('**Date:** ' + Date.today().format() + '\n\n');
        
        // Extract key points from content
        List<String> keyPoints = extractKeyPoints(content);
        
        executive.append('## Key Findings\n\n');
        for (Integer i = 0; i < Math.min(keyPoints.size(), 5); i++) {
            executive.append('• ' + keyPoints[i] + '\n');
        }
        
        executive.append('\n## Recommendations\n\n');
        executive.append('Based on the analysis, the following actions are recommended:\n\n');
        
        // Extract actionable items
        List<String> recommendations = extractRecommendations(content);
        for (Integer i = 0; i < Math.min(recommendations.size(), 3); i++) {
            executive.append((i+1) + '. ' + recommendations[i] + '\n');
        }
        
        executive.append('\n## Next Steps\n\n');
        executive.append('• Review detailed analysis\n');
        executive.append('• Implement recommended actions\n');
        executive.append('• Schedule follow-up assessment\n');
        
    } catch (Exception e) {
        System.debug('Error formatting as executive summary: ' + e.getMessage());
        return content;
    }
    
    return executive.toString();
}

/**
 * Format content as technical document
 */
private static String formatAsTechnicalDocument(String content) {
    StringBuilder technical = new StringBuilder();
    
    try {
        technical.append('# Technical Documentation\n\n');
        technical.append('## Overview\n\n');
        
        // Add technical metadata
        technical.append('**Analysis Framework:** Context-Aware Document Engine\n');
        technical.append('**Processing Date:** ' + DateTime.now().format() + '\n');
        technical.append('**Version:** 1.0\n\n');
        
        technical.append('## Technical Details\n\n');
        technical.append(content);
        
        technical.append('\n\n## Implementation Notes\n\n');
        technical.append('• This analysis was generated using AI-powered document processing\n');
        technical.append('• Results are based on content analysis and pattern recognition\n');
        technical.append('• For technical support, contact system administrators\n');
        
        technical.append('\n## Appendix\n\n');
        technical.append('### System Information\n');
        technical.append('- Processing Engine: Salesforce Apex\n');
        technical.append('- Analysis Type: Contextual Document Analysis\n');
        technical.append('- Data Processing: Real-time\n');
        
    } catch (Exception e) {
        System.debug('Error formatting as technical document: ' + e.getMessage());
        return content;
    }
    
    return technical.toString();
}

/**
 * Format content as report
 */
private static String formatAsReport(String content) {
    StringBuilder report = new StringBuilder();
    
    try {
        report.append('# Document Analysis Report\n\n');
        
        // Report header
        report.append('**Report Generation Date:** ' + DateTime.now().format() + '\n');
        report.append('**Generated By:** Context-Aware Document Engine\n');
        report.append('**Report Type:** Comprehensive Analysis\n\n');
        
        report.append('---\n\n');
        
        // Table of contents
        report.append('## Table of Contents\n\n');
        report.append('1. Executive Summary\n');
        report.append('2. Analysis Results\n');
        report.append('3. Key Findings\n');
        report.append('4. Recommendations\n');
        report.append('5. Conclusion\n\n');
        
        report.append('---\n\n');
        
        // Main content
        report.append('## Analysis Results\n\n');
        report.append(content);
        
        // Report footer
        report.append('\n\n---\n\n');
        report.append('## Conclusion\n\n');
        report.append('This report provides a comprehensive analysis of the document context. ');
        report.append('The findings presented above should be reviewed in conjunction with ');
        report.append('organizational policies and business objectives.\n\n');
        
        report.append('**Report End**\n');
        report.append('*Generated automatically by Salesforce Document Engine*');
        
    } catch (Exception e) {
        System.debug('Error formatting as report: ' + e.getMessage());
        return content;
    }
    
    return report.toString();
}

/**
 * Extract key points from content
 */
private static List<String> extractKeyPoints(String content) {
    List<String> keyPoints = new List<String>();
    
    try {
        List<String> lines = content.split('\n');
        for (String line : lines) {
            line = line.trim();
            // Look for lines that seem like key points
            if (line.startsWith('•') || line.startsWith('-') || 
                line.contains('important') || line.contains('key') ||
                line.contains('significant') || line.contains('critical')) {
                keyPoints.add(line.replaceAll('^[•\\-]\\s*', ''));
            }
        }
        
        // If no bullet points found, extract first sentences
        if (keyPoints.isEmpty()) {
            Pattern sentencePattern = Pattern.compile('[.!?]+\\s+');
            List<String> sentences = sentencePattern.split(content);
            for (Integer i = 0; i < Math.min(sentences.size(), 3); i++) {
                if (String.isNotBlank(sentences[i]) && sentences[i].length() > 20) {
                    keyPoints.add(sentences[i].trim());
                }
            }
        }
        
    } catch (Exception e) {
        System.debug('Error extracting key points: ' + e.getMessage());
    }
    
    return keyPoints;
}

/**
 * Extract recommendations from content
 */
private static List<String> extractRecommendations(String content) {
    List<String> recommendations = new List<String>();
    
    try {
        List<String> lines = content.split('\n');
        Boolean inRecommendationSection = false;
        
        for (String line : lines) {
            line = line.trim();
            
            // Check if we're entering a recommendations section
            if (line.toLowerCase().contains('recommend') || 
                line.toLowerCase().contains('suggest') ||
                line.toLowerCase().contains('should')) {
                inRecommendationSection = true;
            }
            
            // Extract recommendations
            if (inRecommendationSection && (line.startsWith('•') || line.startsWith('-') ||
                line.toLowerCase().contains('implement') || 
                line.toLowerCase().contains('consider') ||
                line.toLowerCase().contains('improve'))) {
                recommendations.add(line.replaceAll('^[•\\-]\\s*', ''));
            }
            
            // Stop if we hit a new section
            if (line.startsWith('#') && !line.toLowerCase().contains('recommend')) {
                inRecommendationSection = false;
            }
        }
        
        // If no specific recommendations found, generate generic ones
        if (recommendations.isEmpty()) {
            recommendations.add('Review the analysis results thoroughly');
            recommendations.add('Implement suggested improvements where applicable');
            recommendations.add('Monitor progress and reassess periodically');
        }
        
    } catch (Exception e) {
        System.debug('Error extracting recommendations: ' + e.getMessage());
    }
    
    return recommendations;
}

// Utility methods for document pattern analysis

/**
 * Calculate frequency trend from monthly distribution
 */
private static String calculateFrequencyTrend(Map<String, Integer> monthlyDistribution) {
    try {
        if (monthlyDistribution == null || monthlyDistribution.isEmpty()) {
            return 'No trend data available';
        }
        
       
List<String> sortedMonths = new List<String>(monthlyDistribution.keySet());
        sortedMonths.sort();
        
        if (sortedMonths.size() < 2) {
            return 'Insufficient data for trend analysis';
        }
        
        Integer firstValue = monthlyDistribution.get(sortedMonths[0]);
        Integer lastValue = monthlyDistribution.get(sortedMonths[sortedMonths.size() - 1]);
        
        if (lastValue > firstValue) {
            return 'Increasing trend';
        } else if (lastValue < firstValue) {
            return 'Decreasing trend';
        } else {
            return 'Stable trend';
        }
    } catch (Exception e) {
        System.debug('Error calculating frequency trend: ' + e.getMessage());
        return 'Trend calculation failed';
    }
}

/**
 * Calculate document complexity based on multiple factors
 */
private static Decimal calculateDocumentComplexity(ContextAwareDocumentEngine.DocumentContext doc) {
    Decimal complexity = 0.0;
    try {
        // Content length factor
        if (doc.summary != null) {
            Integer contentLength = doc.summary.length();
            complexity += Math.min(contentLength / 1000.0, 5.0); // Max 5 points for length
        }
        
        // Entity complexity
        if (doc.extractedEntities != null && !doc.extractedEntities.isEmpty()) {
            complexity += Math.min(doc.extractedEntities.size() / 10.0, 3.0); // Max 3 points for entities
        }
        
        // Theme complexity
        if (doc.themes != null && !doc.themes.isEmpty()) {
            complexity += Math.min(doc.themes.size() / 5.0, 2.0); // Max 2 points for themes
        }
        
        // Document type complexity
        if (doc.documentType != null) {
            switch on doc.documentType.toLowerCase() {
                when 'contract', 'legal', 'technical' {
                    complexity += 2.0;
                }
                when 'policy', 'procedure', 'specification' {
                    complexity += 1.5;
                }
                when 'memo', 'email', 'note' {
                    complexity += 0.5;
                }
                when else {
                    complexity += 1.0;
                }
            }
        }
        
        return Math.min(complexity, 10.0); // Cap at 10
    } catch (Exception e) {
        System.debug('Error calculating document complexity: ' + e.getMessage());
        return 1.0; // Default complexity
    }
}

/**
 * Calculate average from list of decimals
 */
private static Decimal calculateAverage(List<Decimal> values) {
    if (values == null || values.isEmpty()) return 0.0;
    
    Decimal sum = 0.0;
    for (Decimal value : values) {
        sum += value;
    }
    return sum / values.size();
}

/**
 * Calculate median from list of decimals
 */
private static Decimal calculateMedian(List<Decimal> values) {
    if (values == null || values.isEmpty()) return 0.0;
    
    List<Decimal> sortedValues = new List<Decimal>(values);
    sortedValues.sort();
    
    Integer size = sortedValues.size();
    if (Math.mod(size, 2) == 0) {
        return (sortedValues[size/2 - 1] + sortedValues[size/2]) / 2;
    } else {
        return sortedValues[size/2];
    }
}

/**
 * Calculate range from list of decimals
 */
private static Map<String, Decimal> calculateRange(List<Decimal> values) {
    Map<String, Decimal> range = new Map<String, Decimal>();
    if (values == null || values.isEmpty()) {
        range.put('min', 0.0);
        range.put('max', 0.0);
        range.put('range', 0.0);
        return range;
    }
    
    Decimal min = values[0];
    Decimal max = values[0];
    
    for (Decimal value : values) {
        if (value < min) min = value;
        if (value > max) max = value;
    }
    
    range.put('min', min);
    range.put('max', max);
    range.put('range', max - min);
    return range;
}

/**
 * Categorize complexity scores
 */
private static Map<String, Integer> categorizeComplexity(List<Decimal> complexityScores) {
    Map<String, Integer> categories = new Map<String, Integer>();
    categories.put('Low (0-3)', 0);
    categories.put('Medium (3-7)', 0);
    categories.put('High (7-10)', 0);
    
    for (Decimal score : complexityScores) {
        if (score <= 3) {
            categories.put('Low (0-3)', categories.get('Low (0-3)') + 1);
        } else if (score <= 7) {
            categories.put('Medium (3-7)', categories.get('Medium (3-7)') + 1);
        } else {
            categories.put('High (7-10)', categories.get('High (7-10)') + 1);
        }
    }
    
    return categories;
}

/**
 * Calculate timespan between creation times
 */
private static Map<String, Object> calculateTimespan(List<DateTime> creationTimes) {
    Map<String, Object> timespan = new Map<String, Object>();
    
    if (creationTimes == null || creationTimes.size() < 2) {
        timespan.put('days', 0);
        timespan.put('earliest', null);
        timespan.put('latest', null);
        return timespan;
    }
    
    DateTime earliest = creationTimes[0];
    DateTime latest = creationTimes[0];
    
    for (DateTime dt : creationTimes) {
        if (dt < earliest) earliest = dt;
        if (dt > latest) latest = dt;
    }
    
    timespan.put('days', earliest.date().daysBetween(latest.date()));
    timespan.put('earliest', earliest);
    timespan.put('latest', latest);
    
    return timespan;
}

/**
 * Calculate creation velocity (documents per day)
 */
private static Decimal calculateCreationVelocity(List<DateTime> creationTimes) {
    if (creationTimes == null || creationTimes.size() < 2) return 0.0;
    
    Map<String, Object> timespan = calculateTimespan(creationTimes);
    Integer days = (Integer) timespan.get('days');
    
    if (days == 0) days = 1; // Avoid division by zero
    
    return (Decimal) creationTimes.size() / days;
}

/**
 * Identify peak creation periods
 */
private static List<String> identifyPeakPeriods(List<DateTime> creationTimes) {
    List<String> peakPeriods = new List<String>();
    Map<String, Integer> monthCounts = new Map<String, Integer>();
    
    for (DateTime dt : creationTimes) {
        String monthKey = dt.format('yyyy-MM');
        monthCounts.put(monthKey, monthCounts.containsKey(monthKey) ? 
                       monthCounts.get(monthKey) + 1 : 1);
    }
    
    // Find maximum count
    Integer maxCount = 0;
    for (Integer count : monthCounts.values()) {
        if (count > maxCount) maxCount = count;
    }
    
    // Identify months with peak activity (80% of max)
    Integer threshold = (Integer)(maxCount * 0.8);
    for (String month : monthCounts.keySet()) {
        if (monthCounts.get(month) >= threshold) {
            peakPeriods.add(month);
        }
    }
    
    return peakPeriods;
}

/**
 * Calculate modification frequency
 */
private static Decimal calculateModificationFrequency(List<DateTime> modificationTimes) {
    if (modificationTimes == null || modificationTimes.isEmpty()) return 0.0;
    
    Map<String, Object> timespan = calculateTimespan(modificationTimes);
    Integer days = (Integer) timespan.get('days');
    
    if (days == 0) days = 1;
    
    return (Decimal) modificationTimes.size() / days;
}

/**
 * Analyze maintenance pattern
 */
private static Map<String, Object> analyzeMaintenancePattern(
    List<DateTime> creationTimes, 
    List<DateTime> modificationTimes
) {
    Map<String, Object> maintenancePattern = new Map<String, Object>();
    
    if (creationTimes.isEmpty()) {
        maintenancePattern.put('pattern', 'No data');
        return maintenancePattern;
    }
    
    Decimal creationVelocity = calculateCreationVelocity(creationTimes);
    Decimal modificationVelocity = calculateModificationFrequency(modificationTimes);
    
    if (modificationVelocity > creationVelocity * 1.5) {
        maintenancePattern.put('pattern', 'High maintenance');
    } else if (modificationVelocity > creationVelocity * 0.5) {
        maintenancePattern.put('pattern', 'Active maintenance');
    } else {
        maintenancePattern.put('pattern', 'Low maintenance');
    }
    
    maintenancePattern.put('creationVelocity', creationVelocity);
    maintenancePattern.put('modificationVelocity', modificationVelocity);
    
    return maintenancePattern;
}

/**
 * Calculate average document age
 */
private static Decimal calculateAverageAge(List<DateTime> creationTimes) {
    if (creationTimes == null || creationTimes.isEmpty()) return 0.0;
    
    DateTime now = DateTime.now();
    Long totalDays = 0;
    
    for (DateTime creationTime : creationTimes) {
        totalDays += creationTime.date().daysBetween(now.date());
    }
    
    return (Decimal) totalDays / creationTimes.size();
}

/**
 * Categorize documents by age
 */
private static Map<String, Integer> categorizeDocumentsByAge(List<DateTime> creationTimes) {
    Map<String, Integer> ageCategories = new Map<String, Integer>();
    ageCategories.put('Recent (0-30 days)', 0);
    ageCategories.put('Medium (30-180 days)', 0);
    ageCategories.put('Old (180+ days)', 0);
    
    DateTime now = DateTime.now();
    
    for (DateTime creationTime : creationTimes) {
        Integer daysDiff = creationTime.date().daysBetween(now.date());
        
        if (daysDiff <= 30) {
            ageCategories.put('Recent (0-30 days)', ageCategories.get('Recent (0-30 days)') + 1);
        } else if (daysDiff <= 180) {
            ageCategories.put('Medium (30-180 days)', ageCategories.get('Medium (30-180 days)') + 1);
        } else {
            ageCategories.put('Old (180+ days)', ageCategories.get('Old (180+ days)') + 1);
        }
    }
    
    return ageCategories;
}

/**
 * Find dominant document type
 */
private static String findDominantType(Map<String, Integer> typeCount) {
    String dominantType = 'None';
    Integer maxCount = 0;
    
    for (String type : typeCount.keySet()) {
        Integer count = typeCount.get(type);
        if (count > maxCount) {
            maxCount = count;
            dominantType = type;
        }
    }
    
    return dominantType;
}

/**
 * Calculate type diversity index
 */
private static Decimal calculateTypeDiversity(Map<String, Integer> typeCount) {
    if (typeCount.isEmpty()) return 0.0;
    
    Integer totalDocs = 0;
    for (Integer count : typeCount.values()) {
        totalDocs += count;
    }
    
    Decimal diversity = 0.0;
    for (Integer count : typeCount.values()) {
        if (count > 0) {
            Decimal proportion = (Decimal) count / totalDocs;
            diversity -= proportion * Math.log(proportion) / Math.log(2);
        }
    }
    
    return diversity;
}

/**
 * Identify document clusters based on similarity
 */
private static Map<String, List<String>> identifyDocumentClusters(
    List<ContextAwareDocumentEngine.DocumentContext> documents, 
    Decimal similarityThreshold
) {
    Map<String, List<String>> clusters = new Map<String, List<String>>();
    Set<String> processed = new Set<String>();
    Integer clusterIndex = 1;
    
    for (ContextAwareDocumentEngine.DocumentContext doc : documents) {
        if (processed.contains(doc.documentId)) continue;
        
        List<String> cluster = new List<String>();
        cluster.add(doc.documentId);
        processed.add(doc.documentId);
        
        // Find similar documents
        for (ContextAwareDocumentEngine.DocumentContext otherDoc : documents) {
            if (!processed.contains(otherDoc.documentId)) {
                Decimal similarity = calculateDocumentSimilarity(doc, otherDoc);
                if (similarity >= similarityThreshold) {
                    cluster.add(otherDoc.documentId);
                    processed.add(otherDoc.documentId);
                }
            }
        }
        
        if (cluster.size() > 1) {
            clusters.put('Cluster_' + clusterIndex, cluster);
            clusterIndex++;
        }
    }
    
    return clusters;
}

/**
 * Calculate average similarity from similarity matrix
 */
private static Decimal calculateAverageSimilarity(Map<String, Map<String, Decimal>> similarityMatrix) {
    if (similarityMatrix.isEmpty()) return 0.0;
    
    Decimal totalSimilarity = 0.0;
    Integer pairCount = 0;
    
    for (String doc1 : similarityMatrix.keySet()) {
        Map<String, Decimal> similarities = similarityMatrix.get(doc1);
        for (Decimal similarity : similarities.values()) {
            totalSimilarity += similarity;
            pairCount++;
        }
    }
    
    return pairCount > 0 ? totalSimilarity / pairCount : 0.0;
}

/**
 * Convert Set Map to List Map for serialization
 */
private static Map<String, List<String>> convertSetMapToListMap(Map<String, Set<String>> setMap) {
    Map<String, List<String>> listMap = new Map<String, List<String>>();
    
    for (String key : setMap.keySet()) {
        listMap.put(key, new List<String>(setMap.get(key)));
    }
    
    return listMap;
}

/**
 * Identify central entities based on frequency and co-occurrence
 */
private static List<String> identifyCentralEntities(
    Map<String, Integer> entityFrequency,
    Map<String, Set<String>> entityCoOccurrence
) {
    List<String> centralEntities = new List<String>();
    Map<String, Decimal> centralityScores = new Map<String, Decimal>();
    
    // Find maximum frequency (for normalization)
    Integer maxFrequency = 0;
    for (Integer freq : entityFrequency.values()) {
        if (freq > maxFrequency) maxFrequency = freq;
    }
    
    // Calculate centrality score for each entity
    for (String entity : entityFrequency.keySet()) {
        Decimal score = 0.0;
        
        // Frequency component (normalized, weighted 50%)
        Integer frequency = entityFrequency.get(entity);
        score += maxFrequency > 0 ? ((Decimal) frequency / maxFrequency) * 50 : 0;
        
        // Co-occurrence component (5 points per connection)
        if (entityCoOccurrence.containsKey(entity)) {
            Set<String> coOccurringEntities = entityCoOccurrence.get(entity);
            score += coOccurringEntities.size() * 5;
        }
        
        centralityScores.put(entity, score);
    }
    
    // Convert to sortable structure
    List<EntityScore> sortedEntities = new List<EntityScore>();
    for (String entity : centralityScores.keySet()) {
        sortedEntities.add(new EntityScore(entity, centralityScores.get(entity)));
    }
    sortedEntities.sort(); // Requires compareTo in EntityScore
    
    // Pick top 10 entities
    for (Integer i = 0; i < Math.min(sortedEntities.size(), 10); i++) {
        centralEntities.add(sortedEntities[i].entity);
    }
    
    return centralEntities;
}

    
    /**
     * Process template sections with contextual intelligence
     */
    private static String processTemplateWithContext(
        TemplateStructure template, 
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext,
        Map<String, Object> parameters
    ) {
        StringBuilder processedContent = new StringBuilder();
        
        for (TemplateSection section : template.sections) {
            String sectionContent = '';
            
            switch on section.type {
                when 'STATIC' {
                    sectionContent = section.content;
                }
                when 'DYNAMIC_AI' {
                    sectionContent = generateAIContent(section, folderContext, parameters);
                }
                when 'CONTEXTUAL_SUMMARY' {
                    sectionContent = generateContextualSummary(section, folderContext);
                }
                when 'CROSS_REFERENCE' {
                    sectionContent = generateCrossReferences(section, folderContext);
                }
                when 'ENTITY_CONSOLIDATION' {
                    sectionContent = generateEntityConsolidation(section, folderContext);
                }
                when 'CONDITIONAL' {
                    if (evaluateCondition(section.condition, folderContext, parameters)) {
                        sectionContent = processTemplateWithContext(
                            section.nestedTemplate, 
                            folderContext, 
                            parameters
                        );
                    }
                }
            }
            
            processedContent.append(sectionContent);
        }
        
        return processedContent.toString();
    }
    
    /**
     * Generate AI-driven section content
     */
    private static String generateAIContent(
        TemplateSection section, 
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext,
        Map<String, Object> parameters
    ) {
        // Build AI prompt for this specific section
        String sectionPrompt = buildSectionPrompt(section, folderContext, parameters);
        
        // Get AI model from parameters or use default
        String selectedModel = (String) parameters.get('selectedAIModel');
        if (String.isBlank(selectedModel)) {
            selectedModel = 'einstein_gpt_default';
        }
        
        // Generate content using AI
        String aiGeneratedContent = AIModelManager.processWithEinstein(
            selectedModel, 
            sectionPrompt, 
            ''
        );
        
        return aiGeneratedContent;
    }
    
    /**
     * Generate contextual summary section
     */
    private static String generateContextualSummary(
        TemplateSection section, 
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext
    ) {
        StringBuilder summary = new StringBuilder();
        
        // Add collection-level summary
        summary.append('## Document Collection Analysis\n\n');
        summary.append(folderContext.contextualSummary + '\n\n');
        
        // Add key insights
        if (folderContext.crossDocumentInsights != null && 
            !folderContext.crossDocumentInsights.isEmpty()) {
            
            summary.append('### Key Insights:\n');
            
            for (String insight : folderContext.crossDocumentInsights.keySet()) {
                summary.append(
                    '- **' + insight + '**: ' + 
                    folderContext.crossDocumentInsights.get(insight) + '\n'
                );
            }
            summary.append('\n');
        }
        
        // Add shared concepts
        if (folderContext.sharedConcepts != null && 
            !folderContext.sharedConcepts.isEmpty()) {
            
            summary.append('### Shared Concepts: ');
            summary.append(String.join(folderContext.sharedConcepts, ', ') + '\n\n');
        }
        
        return summary.toString();
    }
    
    /**
     * Generate cross-references from relevant documents
     */
    private static String generateCrossReferences(
        TemplateSection section, 
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext
    ) {
        StringBuilder references = new StringBuilder();
        
        references.append('## Referenced Documents\n\n');
        
        Integer refCount = 1;
        for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
            if (doc.relevanceScore > 0.3) { // Only include relevant documents
                references.append('[' + refCount + '] **' + doc.documentName + '**\n');
                references.append('   - *Relevance Score: ' + doc.relevanceScore.setScale(2) + '*\n');
                references.append('   - *Summary: ' + doc.summary + '*\n\n');
                refCount++;
            }
        }
        
        return references.toString();
    }
    
   
    private static String generateEntityConsolidation(TemplateSection section,ContextAwareDocumentEngine.FolderContextAnalysis folderContext) {
        StringBuilder consolidation = new StringBuilder();
        
        consolidation.append('## Entity Analysis Across Documents\n\n');
        
        if (folderContext.entityFrequency != null && !folderContext.entityFrequency.isEmpty()) {
            consolidation.append('### Most Frequent Entities:\n');
            
            // Sort entities by frequency
            List<EntityFrequency> sortedEntities = new List<EntityFrequency>();
            for (String entity : folderContext.entityFrequency.keySet()) {
                sortedEntities.add(new EntityFrequency(entity, folderContext.entityFrequency.get(entity)));
            }
            sortedEntities.sort();
            
            for (EntityFrequency ef : sortedEntities) {
                if (ef.frequency > 1) { // Only show entities that appear in multiple documents
                    consolidation.append('- **' + ef.entity + '**: Mentioned in ' + ef.frequency + ' document(s)\n');
                }
            }
            consolidation.append('\n');
        }
        
        return consolidation.toString();
    }

     private static String applyContextualEnhancements(String content,ContextAwareDocumentEngine.FolderContextAnalysis folderContext) {
        String enhancedContent = content;
        
        // Add automatic source attribution (Anara-style)
        enhancedContent = addSourceAttributions(enhancedContent, folderContext);
        
        // Add cross-document links
        enhancedContent = addCrossDocumentLinks(enhancedContent, folderContext);
        
        // Add contextual footnotes
        enhancedContent = addContextualFootnotes(enhancedContent, folderContext);
        
        return enhancedContent;
    }
    private static String addSourceAttributions(String content,ContextAwareDocumentEngine.FolderContextAnalysis folderContext) {
        StringBuilder attributedContent = new StringBuilder(content);
        
        // Add source attribution section
        attributedContent.append('\n\n---\n');
        attributedContent.append('## Sources and References\n\n');
        attributedContent.append('*This document was generated using contextual intelligence from the following sources:*\n\n');
        
        Integer sourceNum = 1;
        for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
            if (doc.relevanceScore > 0.2) {
                attributedContent.append('**[' + sourceNum + ']** ' + doc.documentName + '\n');
                attributedContent.append('   - Relevance: ' + doc.relevanceScore.setScale(2) + '\n');
                attributedContent.append('   - Key Contributions: ' + String.join(doc.keyEntities.subList(0, Math.min(3, doc.keyEntities.size())), ', ') + '\n\n');
                sourceNum++;
            }
        }
        
        return attributedContent.toString();
    }




     public class EntityFrequency implements Comparable {
        public String entity;
        public Integer frequency;
        
        public EntityFrequency(String entity, Integer frequency) {
            this.entity = entity;
            this.frequency = frequency;
        }
        
        public Integer compareTo(Object compareTo) {
            EntityFrequency other = (EntityFrequency) compareTo;
            return other.frequency.compareTo(this.frequency); // Descending order
        }
    }
}
