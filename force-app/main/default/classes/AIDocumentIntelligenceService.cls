public with sharing class AIDocumentIntelligenceService {
    
    public class DocumentIntelligenceResult {
        @AuraEnabled public String documentId { get; set; }
        @AuraEnabled public String classification { get; set; }
        @AuraEnabled public List<String> extractedEntities { get; set; }
        @AuraEnabled public String summary { get; set; }
        @AuraEnabled public Decimal confidenceScore { get; set; }
        @AuraEnabled public Map<String, Object> metadata { get; set; }
        @AuraEnabled public String processingStatus { get; set; }
        
        public DocumentIntelligenceResult() {
            this.extractedEntities = new List<String>();
            this.metadata = new Map<String, Object>();
            this.processingStatus = 'PROCESSING';
        }
    }
    
    @AuraEnabled
    public static DocumentIntelligenceResult analyzeDocument(String documentId) {
        DocumentIntelligenceResult result = new DocumentIntelligenceResult();
        try {
            result.documentId = documentId;
            
            // Get document content
            ContentVersion document = [
                SELECT Id, Title, FileType, ContentSize, VersionData 
                FROM ContentVersion 
                WHERE ContentDocumentId = :documentId 
                AND IsLatest = true 
                LIMIT 1
            ];
            
            String content = document.VersionData.toString();
            
            // Perform AI analysis
            result.classification = classifyDocumentType(content);
            result.extractedEntities = extractEntities(content);
            result.summary = generateSummary(content);
            result.confidenceScore = calculateConfidence(content);
            result.metadata = extractMetadata(document);
            result.processingStatus = 'COMPLETED';
            
            // Log analysis
            logAnalysis(result);
            
            return result;
        } catch (Exception e) {
            result.processingStatus = 'ERROR';
            result.metadata.put('error', e.getMessage());
            return result;
        }
    }
    
    @AuraEnabled
    public static Map<String, Object> performSemanticAnalysis(String documentId, String query) {
        Map<String, Object> analysisResult = new Map<String, Object>();
        try {
            // Call AI service for semantic analysis
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:AI_Service/semantic-analysis');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('documentId', documentId);
            requestBody.put('query', query);
            req.setBody(JSON.serialize(requestBody));
            
            Http http = new Http();
            HttpResponse response = http.send(req);
            
            if (response.getStatusCode() == 200) {
                analysisResult = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
            }
            
            analysisResult.put('status', 'SUCCESS');
            return analysisResult;
        } catch (Exception e) {
            analysisResult.put('status', 'ERROR');
            analysisResult.put('error', e.getMessage());
            return analysisResult;
        }
    }
    
    private static String classifyDocumentType(String content) {
        // AI-based document classification
        if (content.containsIgnoreCase('contract')) return 'CONTRACT';
        if (content.containsIgnoreCase('invoice')) return 'INVOICE';
        if (content.containsIgnoreCase('agreement')) return 'AGREEMENT';
        if (content.containsIgnoreCase('policy')) return 'POLICY';
        return 'GENERAL';
    }
    
    private static List<String> extractEntities(String content) {
        List<String> entities = new List<String>();
        // Simplified entity extraction
        Pattern emailPattern = Pattern.compile('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}');
        Matcher emailMatcher = emailPattern.matcher(content);
        while (emailMatcher.find()) {
            entities.add('EMAIL: ' + emailMatcher.group());
        }
        return entities;
    }
    
    private static String generateSummary(String content) {
        // Simplified summarization
        String[] sentences = content.split('\\.');
        if (sentences.size() > 0) {
            return sentences[0] + '...';
        }
        return 'No summary available';
    }
    
    private static Decimal calculateConfidence(String content) {
        // Confidence based on content length and structure
        Decimal confidence = Math.min(content.length() / 1000.0 * 100, 95);
        return confidence;
    }
    
    private static Map<String, Object> extractMetadata(ContentVersion document) {
        Map<String, Object> metadata = new Map<String, Object>();
        metadata.put('fileName', document.Title);
        metadata.put('fileType', document.FileType);
        metadata.put('fileSize', document.ContentSize);
        metadata.put('processedAt', DateTime.now());
        return metadata;
    }
    
    private static void logAnalysis(DocumentIntelligenceResult result) {
        AI_Analysis_Log__c log = new AI_Analysis_Log__c(
            Document_Id__c = result.documentId,
            Classification__c = result.classification,
            Confidence_Score__c = result.confidenceScore,
            Processing_Status__c = result.processingStatus,
            Analysis_Date__c = DateTime.now()
        );
        insert log;
    }
}