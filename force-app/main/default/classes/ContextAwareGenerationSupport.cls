/**
 * Enhanced support methods for context-aware generation
 */
public class ContextAwareGenerationSupport {
    
    /**
     * Generate context merge fields based on folder analysis
     */
    public static Map<String, Object> generateContextMergeFields(
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext,
        Map<String, Integer> aggregatedEntities,
        String aiModel
    ) {
        Map<String, Object> mergeFields = new Map<String, Object>();
        
        try {
            // Document count and statistics
            mergeFields.put('DOCUMENT_COUNT', folderContext.documents.size());
            mergeFields.put('ANALYSIS_DATE', Date.today().format());
            mergeFields.put('AI_MODEL_USED', aiModel);
            
            // Most frequent entities
            List<String> topEntities = getTopEntities(aggregatedEntities, 5);
            mergeFields.put('TOP_ENTITIES', String.join(topEntities, ', '));
            
            // Theme-based merge fields
            if (folderContext.commonThemes != null && !folderContext.commonThemes.isEmpty()) {
                mergeFields.put('PRIMARY_THEME', folderContext.commonThemes[0]);
                mergeFields.put('ALL_THEMES', String.join(folderContext.commonThemes, ', '));
                mergeFields.put('THEME_COUNT', folderContext.commonThemes.size());
            }
            
            // Document type distribution
            Map<String, Integer> typeDistribution = calculateDocumentTypeDistribution(folderContext);
            String dominantType = getDominantDocumentType(typeDistribution);
            mergeFields.put('DOMINANT_DOC_TYPE', dominantType);
            
            // Time-based context
            mergeFields.put('CONTEXT_ANALYSIS_TIME', String.valueOf(DateTime.now()));
            mergeFields.put('GENERATION_TIMESTAMP', String.valueOf(System.now()));
            
            // Context quality indicators
            Decimal contextQuality = calculateContextQuality(folderContext);
            mergeFields.put('CONTEXT_QUALITY_SCORE', contextQuality);
            mergeFields.put('CONTEXT_CONFIDENCE', contextQuality > 80 ? 'HIGH' : contextQuality > 60 ? 'MEDIUM' : 'LOW');
            
            // Cross-document relationships
            Integer relationshipCount = 0;
            if (folderContext.crossDocumentRelations != null) {
                Map<String, Object> similarities = (Map<String, Object>)folderContext.crossDocumentRelations.get('documentSimilarities');
                if (similarities != null) {
                    relationshipCount = similarities.size();
                }
            }
            mergeFields.put('CROSS_DOCUMENT_RELATIONSHIPS', relationshipCount);
            
            // AI-powered insights
            //mergeFields.put('AI_INSIGHTS_AVAILABLE', folderContext.contextSummary != null);
            mergeFields.put('SUGGESTED_TEMPLATES_COUNT', folderContext.suggestedTemplates != null ? folderContext.suggestedTemplates.size() : 0);
            
        } catch (Exception e) {
            System.debug('Error generating context merge fields: ' + e.getMessage());
        }
        
        return mergeFields;
    }

    // --- Helper Methods ---
    
    private static Map<String, Integer> calculateDocumentTypeDistribution(
        ContextAwareDocumentEngine.FolderContextAnalysis folderContext
    ) {
        Map<String, Integer> distribution = new Map<String, Integer>();
        for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
            String docType = doc.documentType != null ? doc.documentType : 'UNKNOWN';
            distribution.put(docType, distribution.containsKey(docType) ? distribution.get(docType) + 1 : 1);
        }
        return distribution;
    }

    private static String getDominantDocumentType(Map<String, Integer> typeDistribution) {
        String dominantType = 'MIXED';
        Integer maxCount = 0;
        for (String type : typeDistribution.keySet()) {
            Integer count = typeDistribution.get(type);
            if (count > maxCount) {
                maxCount = count;
                dominantType = type;
            }
        }
        return dominantType;
    }

    private static Decimal calculateContextQuality(ContextAwareDocumentEngine.FolderContextAnalysis folderContext) {
        Decimal qualityScore = 0;

        // Document count factor (0-30 points)
        Integer docCount = folderContext.documents.size();
        if (docCount >= 10) qualityScore += 30;
        else if (docCount >= 5) qualityScore += 20;
        else if (docCount >= 2) qualityScore += 10;

        // Theme diversity factor (0-25 points)
        Integer themeCount = folderContext.commonThemes != null ? folderContext.commonThemes.size() : 0;
        if (themeCount >= 5) qualityScore += 25;
        else if (themeCount >= 3) qualityScore += 20;
        else if (themeCount >= 1) qualityScore += 10;

        // Cross-document relationships (0-25 points)
        if (folderContext.crossDocumentRelations != null) {
            Map<String, Object> similarities = (Map<String, Object>)folderContext.crossDocumentRelations.get('documentSimilarities');
            if (similarities != null && similarities.size() > 0) {
                qualityScore += 25;
            } else {
                qualityScore += 10;
            }
        }

        // AI analysis completeness (0-20 points)
        Boolean hasMetadata = false;
        for (ContextAwareDocumentEngine.DocumentContext doc : folderContext.documents) {
            if (doc.metadata != null && !doc.metadata.isEmpty()) {
                hasMetadata = true;
                break;
            }
        }
        if (hasMetadata) qualityScore += 20;

        return qualityScore;
    }

    private static List<String> getTopEntities(Map<String, Integer> entityFrequency, Integer limit1) {
        List<EntityFrequency> entityList = new List<EntityFrequency>();
        for (String entity : entityFrequency.keySet()) {
            entityList.add(new EntityFrequency(entity, entityFrequency.get(entity)));
        }
        entityList.sort();
        List<String> topEntities = new List<String>();
        Integer maxItems = Math.min(limit1, entityList.size());
        for (Integer i = 0; i < maxItems; i++) {
            topEntities.add(entityList[i].entity);
        }
        return topEntities;
    }

    public class EntityFrequency implements Comparable {
        public String entity;
        public Integer frequency;
        public EntityFrequency(String entity, Integer frequency) {
            this.entity = entity;
            this.frequency = frequency;
        }
        public Integer compareTo(Object compareTo) {
            EntityFrequency compareToEntity = (EntityFrequency)compareTo;
            if (frequency == compareToEntity.frequency) return 0;
            if (frequency > compareToEntity.frequency) return -1;
            return 1;
        }
    }
}