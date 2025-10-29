public with sharing class AIDocumentIntelligenceService {

    // --- Result wrapper (preserve shape and @AuraEnabled surface) ---
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
            this.confidenceScore = 0;
        }
    }

    // -------------------------
    // Public API
    // -------------------------

    @AuraEnabled
    public static DocumentIntelligenceResult analyzeDocument(String documentId) {
        DocumentIntelligenceResult result = new DocumentIntelligenceResult();
        try {
            result.documentId = documentId;

            // Defensive: ensure ContentVersion exists and is queryable
            ContentVersion cv;
            try {
                cv = [ SELECT Id, Title, FileType, ContentSize, VersionData
                       FROM ContentVersion
                       WHERE ContentDocumentId = :documentId
                         AND IsLatest = true
                       LIMIT 1 ];
            } catch (Exception qex) {
                result.processingStatus = 'ERROR';
                result.metadata.put('error', 'Document not found or ContentVersion query failed: ' + qex.getMessage());
                return result;
            }

            // Safely convert VersionData to text where possible (best-effort)
            String content = '';
            try {
                if (cv.VersionData != null) {
                    // best-effort: attempt to treat VersionData as text; if binary, this may be empty
                    content = cv.VersionData.toString();
                }
            } catch (Exception e) {
                // fallback to empty content (do not throw)
                content = '';
            }

            // Perform analysis using local heuristics (keeps original business logic)
            result.classification = classifyDocumentType(content);
            result.extractedEntities = extractEntities(content);
            result.summary = generateSummary(content);
            result.confidenceScore = calculateConfidence(content);
            result.metadata = extractMetadata(cv);
            result.processingStatus = 'COMPLETED';

            // Best-effort log; do not fail main flow on logging errors
            try {
                logAnalysis(result);
            } catch (Exception le) {
                // log and continue
                System.debug('AIDocumentIntelligenceService.logAnalysis failed: ' + le.getMessage());
            }

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
            // Build request payload
            Map<String, Object> requestBody = new Map<String, Object>();
            requestBody.put('documentId', documentId);
            requestBody.put('query', query);

            // Callout to configured AI service named credential
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:AI_Service/semantic-analysis');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(requestBody));

            Http http = new Http();
            HttpResponse response = http.send(req);

            if (response.getStatusCode() == 200) {
                analysisResult = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            } else {
                analysisResult.put('httpStatus', response.getStatusCode());
                analysisResult.put('httpBody', response.getBody());
            }

            analysisResult.put('status', 'SUCCESS');
            return analysisResult;
        } catch (Exception e) {
            analysisResult.put('status', 'ERROR');
            analysisResult.put('error', e.getMessage());
            return analysisResult;
        }
    }

    // -------------------------
    // Internal helpers (preserve heuristics)
    // -------------------------

    private static String classifyDocumentType(String content) {
        if (String.isBlank(content)) return 'GENERAL';
        String lowerContent = content.toLowerCase();
        if (lowerContent.contains('contract')) return 'CONTRACT';
        if (lowerContent.contains('invoice')) return 'INVOICE';
        if (lowerContent.contains('agreement')) return 'AGREEMENT';
        if (lowerContent.contains('policy')) return 'POLICY';
        return 'GENERAL';
    }

    private static List<String> extractEntities(String content) {
        List<String> entities = new List<String>();
        if (String.isBlank(content)) return entities;

        // Email extraction: best-effort
        try {
            Pattern emailPattern = Pattern.compile('[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}');
            Matcher emailMatcher = emailPattern.matcher(content);
            while (emailMatcher.find()) {
                try {
                    String found = emailMatcher.group();
                    if (!String.isBlank(found)) entities.add('EMAIL: ' + found);
                } catch (Exception me) {
                    // ignore individual matcher errors
                }
            }
        } catch (Exception e) {
            // ignore regex failures
            System.debug('extractEntities regex error: ' + e.getMessage());
        }

        return entities;
    }

    private static String generateSummary(String content) {
        if (String.isBlank(content)) return 'No summary available';
        try {
            List<String> sentences = content.split('\\.');
            if (!sentences.isEmpty()) {
                String first = sentences[0].trim();
                if (String.isNotBlank(first)) return first + '...';
            }
        } catch (Exception e) {
            // fallback
        }
        return 'No summary available';
    }

    private static Decimal calculateConfidence(String content) {
        if (String.isBlank(content)) return 0;
        // keep original heuristic but produce Decimal
        Double raw = ((Double) content.length()) / 1000.0 * 100.0;
        Double clamped = Math.min(raw, 95.0);
        return Decimal.valueOf(clamped);
    }

    private static Map<String, Object> extractMetadata(ContentVersion document) {
        Map<String, Object> metadata = new Map<String, Object>();
        try {
            metadata.put('fileName', document.Title);
            metadata.put('fileType', document.FileType);
            metadata.put('fileSize', document.ContentSize);
            metadata.put('processedAt', Datetime.now());
        } catch (Exception e) {
            metadata.put('processedAt', Datetime.now());
            metadata.put('metadataError', e.getMessage());
        }
        return metadata;
    }

    private static void logAnalysis(DocumentIntelligenceResult result) {
        try {
            // Only attempt insert if the custom SObject exists; keep operation best-effort
            if (Schema.getGlobalDescribe().containsKey('AI_Analysis_Log__c')) {
                AI_Analysis_Log__c logRec = new AI_Analysis_Log__c(
                    Document_Id__c = result.documentId,
                    Classification__c = result.classification,
                    Confidence_Score__c = result.confidenceScore,
                    Processing_Status__c = result.processingStatus,
                    Analysis_Date__c = Datetime.now()
                );
                insert logRec;
            } else {
                System.debug('AI_Analysis_Log__c not present; skipping persistence; analysis=' + JSON.serialize(result));
            }
        } catch (Exception e) {
            // Never throw logging errors back to caller
            System.debug('Failed to persist AI_Analysis_Log__c: ' + e.getMessage());
        }
    }
}