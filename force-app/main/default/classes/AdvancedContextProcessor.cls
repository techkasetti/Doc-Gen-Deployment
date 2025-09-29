/**
 * Phase 4: Advanced Context Processing Engine
 * 
 * Provides advanced processing across a collection of documents:
 *  - Semantic embeddings
 *  - Document similarity
 *  - Cross-document entity relationships
 *  - Contextual insights
 *  - Knowledge graph generation
 */
public class AdvancedContextProcessor {
    
    /**
     * Process a folder of documents and generate advanced contextual insights.
     *
     * @param folderId        The folder ID (LinkedEntityId).
     * @param selectedAIModel The AI model to use for processing.
     * @param queryContext    Additional context query provided by the user.
     * @return Map<String, Object> Context analysis results including:
     *         - documentCollection
     *         - similarityMatrix
     *         - entityRelationships
     *         - contextualInsights
     *         - knowledgeGraph
     *         - processingTimestamp
     *         - selectedAIModel
     *         - totalDocuments
     */
    @AuraEnabled
    public static Map<String, Object> processDocumentCollection(
        String folderId, 
        String selectedAIModel,
        String queryContext
    ) {
        Map<String, Object> processedContext = new Map<String, Object>();
        
        try {
            // --- Step 1: Extract and analyze documents ---
            List<Map<String, Object>> documentData = extractDocumentCollection(folderId);
            
            // --- Step 2: Generate semantic embeddings ---
            Map<String, List<Decimal>> documentEmbeddings = generateDocumentEmbeddings(
                documentData, 
                selectedAIModel
            );
            
            // --- Step 3: Perform similarity analysis ---
            Map<String, Object> similarityMatrix = calculateDocumentSimilarity(documentEmbeddings);
            
            // --- Step 4: Extract entity relationships ---
            Map<String, Object> entityRelationships = extractEntityRelationships(
                documentData, 
                selectedAIModel
            );
            
            // --- Step 5: Generate contextual insights ---
            Map<String, Object> contextualInsights = generateAdvancedInsights(
                documentData,
                similarityMatrix,
                entityRelationships,
                queryContext
            );
            
            // --- Step 6: Build knowledge graph ---
            Map<String, Object> knowledgeGraph = buildKnowledgeGraph(
                documentData,
                entityRelationships
            );
            
            // --- Build final response ---
            processedContext.put('documentCollection', documentData);
            processedContext.put('similarityMatrix', similarityMatrix);
            processedContext.put('entityRelationships', entityRelationships);
            processedContext.put('contextualInsights', contextualInsights);
            processedContext.put('knowledgeGraph', knowledgeGraph);
            processedContext.put('processingTimestamp', DateTime.now());
            processedContext.put('selectedAIModel', selectedAIModel);
            processedContext.put('totalDocuments', documentData.size());
            
        } catch (Exception e) {
            processedContext.put('error', 'Advanced context processing failed: ' + e.getMessage());
        }
        
        return processedContext;
    }
    
    /**
     * Generate embeddings for each document using the selected AI model.
     */
    private static Map<String, List<Decimal>> generateDocumentEmbeddings(
        List<Map<String, Object>> documentData,
        String aiModel
    ) {
        Map<String, List<Decimal>> embeddings = new Map<String, List<Decimal>>();
        
        for (Map<String, Object> doc : documentData) {
            String documentId = (String) doc.get('documentId');
            String content = (String) doc.get('content');
            
            List<Decimal> embedding = generateSemanticEmbedding(content, aiModel);
            embeddings.put(documentId, embedding);
        }
        
        return embeddings;
    }
    
    /**
     * Generate a semantic embedding vector for given content.
     * Falls back to a hash-based embedding if AI service fails.
     */
    private static List<Decimal> generateSemanticEmbedding(
        String content, 
        String aiModel
    ) {
        List<Decimal> embedding = new List<Decimal>();
        
        try {
            if (aiModel.startsWith('einstein_')) {
                embedding = callEinsteinEmbeddingAPI(content);
            } else {
                embedding = callExternalEmbeddingAPI(content, aiModel);
            }
        } catch (Exception e) {
            embedding = generateSimpleEmbedding(content);
        }
        
        return embedding;
    }
    
    /**
     * Extract entity relationships across documents.
     * Identifies entities appearing in multiple documents and builds relationships.
     */
    private static Map<String, Object> extractEntityRelationships(
        List<Map<String, Object>> documentData,
        String aiModel
    ) {
        Map<String, Object> relationships = new Map<String, Object>();
        Map<String, Set<String>> entityOccurrences = new Map<String, Set<String>>();
        List<Map<String, Object>> relationshipPairs = new List<Map<String, Object>>();
        
        // --- Extract entities from each document ---
        for (Map<String, Object> doc : documentData) {
            String documentId = (String) doc.get('documentId');
            String content = (String) doc.get('content');
            
            List<String> entities = extractEntitiesAdvanced(content, aiModel);
            
            for (String entity : entities) {
                if (!entityOccurrences.containsKey(entity)) {
                    entityOccurrences.put(entity, new Set<String>());
                }
                entityOccurrences.get(entity).add(documentId);
            }
        }
        
        // --- Identify cross-document entity relationships ---
        for (String entity : entityOccurrences.keySet()) {
            Set<String> documents = entityOccurrences.get(entity);
            
            if (documents.size() > 1) {
                Map<String, Object> relationship = new Map<String, Object>();
                relationship.put('entity', entity);
                relationship.put('documentIds', new List<String>(documents));
                relationship.put('strength', documents.size());
                
                relationshipPairs.add(relationship);
            }
        }
        
        // --- Build response ---
        relationships.put('entityOccurrences', entityOccurrences);
        relationships.put('crossDocumentRelationships', relationshipPairs);
        relationships.put('totalEntities', entityOccurrences.size());
        
        return relationships;
    }
}
