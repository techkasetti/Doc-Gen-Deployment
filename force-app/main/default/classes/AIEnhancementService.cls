public with sharing class AIEnhancementService {
    private static final String AI_SERVICE_ENDPOINT = 'callout:AnARA_AI_Service';
    private static final Integer TIMEOUT_SECONDS = 30;

    // ----------------
    // DTOs
    // ----------------
    public class AIProcessingRequest {
        @AuraEnabled public String documentId { get; set; }
        @AuraEnabled public String content { get; set; }
        @AuraEnabled public String documentType { get; set; }
        @AuraEnabled public List<String> requestedAnalysis { get; set; }
        @AuraEnabled public Map<String, String> metadata { get; set; }
        public AIProcessingRequest() {
            this.requestedAnalysis = new List<String>();
            this.metadata = new Map<String, String>();
        }
    }

    public class AIProcessingResponse {
        @AuraEnabled public String processingId { get; set; }
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public String classification { get; set; }
        @AuraEnabled public List<AIInsight> insights { get; set; }
        @AuraEnabled public Map<String, Object> complianceAnalysis { get; set; }
        @AuraEnabled public List<String> suggestedClauses { get; set; }
        @AuraEnabled public Integer confidenceScore { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        public AIProcessingResponse() {
            this.insights = new List<AIInsight>();
            this.suggestedClauses = new List<String>();
            this.complianceAnalysis = new Map<String, Object>();
        }
    }

    public class AIInsight {
        @AuraEnabled public String type { get; set; }
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public Integer confidence { get; set; }
        @AuraEnabled public String severity { get; set; }
        @AuraEnabled public List<String> recommendations { get; set; }
        @AuraEnabled public Map<String, String> metadata { get; set; }
        public AIInsight() {
            this.recommendations = new List<String>();
            this.metadata = new Map<String, String>();
        }
    }

    // ----------------
    // Public API methods (business logic preserved)
    // ----------------

    @AuraEnabled public static AIProcessingResponse enhanceDocument(String documentId, List<String> enhancementTypes) {
        try {
            ContentVersion document = getDocumentContent(documentId);
            if (document == null) {
                throw new AuraHandledException('Document not found');
            }
            AIProcessingRequest request = new AIProcessingRequest();
            request.documentId = documentId;
            request.content = extractDocumentText(document);
            request.documentType = determineDocumentType(document);
            request.requestedAnalysis = enhancementTypes;
            request.metadata.put('fileExtension', document.FileExtension);
            request.metadata.put('contentSize', String.valueOf(document.ContentSize));
            request.metadata.put('title', document.Title);
            AIProcessingResponse response = callAIService(request);
            if (response != null && response.success) {
                storeAIResults(documentId, response);
            }
            return response;
        } catch (Exception e) {
            AIProcessingResponse errorResponse = new AIProcessingResponse();
            errorResponse.success = false;
            errorResponse.errorMessage = e.getMessage();
            return errorResponse;
        }
    }

    @AuraEnabled public static AIProcessingResponse analyzeCompliance(String documentId, List<String> regulations) {
        try {
            ContentVersion document = getDocumentContent(documentId);
            if (document == null) {
                throw new AuraHandledException('Document not found');
            }
            AIProcessingRequest request = new AIProcessingRequest();
            request.documentId = documentId;
            request.content = extractDocumentText(document);
            request.requestedAnalysis = new List<String>{'compliance_analysis'};
            request.metadata.put('regulations', String.join(regulations, ','));
            request.metadata.put('analysisType', 'REGULATORY_COMPLIANCE');
            AIProcessingResponse response = callAIService(request);
            response = enhanceComplianceAnalysis(response, regulations);
            if (response != null && response.success) {
                storeComplianceResults(documentId, response);
            }
            return response;
        } catch (Exception e) {
            AIProcessingResponse errorResponse = new AIProcessingResponse();
            errorResponse.success = false;
            errorResponse.errorMessage = 'Compliance analysis failed: ' + e.getMessage();
            return errorResponse;
        }
    }

    @AuraEnabled public static List<String> generateClauseSuggestions(String documentId, String clauseType, String jurisdiction) {
        try {
            ContentVersion document = getDocumentContent(documentId);
            if (document == null) {
                return new List<String>();
            }
            AIProcessingRequest request = new AIProcessingRequest();
            request.documentId = documentId;
            request.content = extractDocumentText(document);
            request.requestedAnalysis = new List<String>{'clause_generation'};
            request.metadata.put('clauseType', clauseType);
            request.metadata.put('jurisdiction', jurisdiction);
            request.metadata.put('documentType', determineDocumentType(document));
            AIProcessingResponse response = callAIService(request);
            if (response != null && response.success && response.suggestedClauses != null) {
                return response.suggestedClauses;
            }
            return new List<String>();
        } catch (Exception e) {
            System.debug('Error generating clause suggestions: ' + e.getMessage());
            return new List<String>();
        }
    }

    @AuraEnabled public static Map<String, Object> performSemanticAnalysis(String documentId, String query) {
        try {
            ContentVersion document = getDocumentContent(documentId);
            if (document == null) {
                return new Map<String, Object>{'success' => false, 'error' => 'Document not found'};
            }
            AIProcessingRequest request = new AIProcessingRequest();
            request.documentId = documentId;
            request.content = extractDocumentText(document);
            request.requestedAnalysis = new List<String>{'semantic_search'};
            request.metadata.put('searchQuery', query);
            request.metadata.put('analysisDepth', 'DETAILED');
            AIProcessingResponse response = callAIService(request);
            Map<String, Object> result = new Map<String, Object>();
            result.put('success', response != null ? response.success : false);
            result.put('results', response != null ? response.complianceAnalysis : null);
            result.put('confidence', response != null ? response.confidenceScore : null);
            if (response != null && response.insights != null && !response.insights.isEmpty()) {
                result.put('insights', response.insights);
            }
            return result;
        } catch (Exception e) {
            return new Map<String, Object>{'success' => false, 'error' => e.getMessage()};
        }
    }

    @AuraEnabled public static AIProcessingResponse detectAnomalies(String documentId) {
        try {
            ContentVersion document = getDocumentContent(documentId);
            if (document == null) {
                throw new AuraHandledException('Document not found');
            }
            AIProcessingRequest request = new AIProcessingRequest();
            request.documentId = documentId;
            request.content = extractDocumentText(document);
            request.requestedAnalysis = new List<String>{'anomaly_detection', 'risk_assessment'};
            request.metadata.put('detectionType', 'COMPREHENSIVE');
            request.metadata.put('riskThreshold', '0.7');
            request.metadata.put('includePatterns', 'true');
            AIProcessingResponse response = callAIService(request);
            if (response != null && response.success) {
                response = processAnomalyResults(response);
                storeAnomalyResults(documentId, response);
            }
            return response;
        } catch (Exception e) {
            AIProcessingResponse errorResponse = new AIProcessingResponse();
            errorResponse.success = false;
            errorResponse.errorMessage = 'Anomaly detection failed: ' + e.getMessage();
            return errorResponse;
        }
    }

    @AuraEnabled public static Map<String, Object> generateExecutiveSummary(String documentId, String summaryType) {
        try {
            ContentVersion document = getDocumentContent(documentId);
            if (document == null) {
                return new Map<String, Object>{'success' => false, 'error' => 'Document not found'};
            }
            AIProcessingRequest request = new AIProcessingRequest();
            request.documentId = documentId;
            request.content = extractDocumentText(document);
            request.requestedAnalysis = new List<String>{'executive_summary'};
            request.metadata.put('summaryType', summaryType);
            request.metadata.put('targetAudience', 'EXECUTIVE');
            request.metadata.put('includeRisks', 'true');
            AIProcessingResponse response = callAIService(request);
            Map<String, Object> result = new Map<String, Object>();
            result.put('success', response != null ? response.success : false);
            if (response != null && response.success) {
                result.put('summary', response.complianceAnalysis != null ? response.complianceAnalysis.get('summary') : null);
                result.put('keyPoints', response.complianceAnalysis != null ? response.complianceAnalysis.get('keyPoints') : null);
                result.put('recommendations', response.suggestedClauses);
                result.put('riskLevel', response.complianceAnalysis != null ? response.complianceAnalysis.get('riskLevel') : null);
            } else {
                result.put('error', response != null ? response.errorMessage : 'No response from AI service');
            }
            return result;
        } catch (Exception e) {
            return new Map<String, Object>{'success' => false, 'error' => e.getMessage()};
        }
    }

    // Batch worker
    @future public static void processDocumentBatch(List<String> documentIds, String analysisType) {
        for (String docId : documentIds) {
            try {
                List<String> analysisTypes = new List<String>{analysisType};
                enhanceDocument(docId, analysisTypes);
            } catch (Exception e) {
                System.debug('Error processing document ' + docId + ': ' + e.getMessage());
            }
        }
    }

    // ----------------------
    // Private helper methods
    // ----------------------

    private static ContentVersion getDocumentContent(String documentId) {
        try {
            List<ContentVersion> cvs = [ SELECT Id, Title, FileExtension, ContentSize, VersionData, CreatedDate, ContentDocumentId, Description
                    FROM ContentVersion
                    WHERE ContentDocumentId = :documentId
                    AND IsLatest = true
                    LIMIT 1 ];
            if (cvs.isEmpty()) return null;
            return cvs[0];
        } catch (Exception e) {
            System.debug('Error retrieving document: ' + e.getMessage());
            return null;
        }
    }

    private static String extractDocumentText(ContentVersion document) {
        try {
            if (document == null || document.VersionData == null) { return ''; }
            String fileExtension = (document.FileExtension == null) ? '' : document.FileExtension.toLowerCase();
            if (isTextFile(fileExtension)) {
                try {
                    return document.VersionData.toString();
                } catch (Exception ex) {
                    return '';
                }
            } else if (fileExtension == 'pdf') {
                return extractPDFText(document.VersionData);
            } else if (fileExtension == 'docx' || fileExtension == 'doc') {
                return extractWordText(document.VersionData);
            } else {
                return 'Title: ' + document.Title + '\nFile Type: ' + fileExtension;
            }
        } catch (Exception e) {
            System.debug('Error extracting text: ' + e.getMessage());
            return 'TEXT_EXTRACTION_ERROR';
        }
    }

    private static String determineDocumentType(ContentVersion document) {
        String content = extractDocumentText(document);
        String title = document.Title == null ? '' : document.Title.toLowerCase();
        if (title != null) {
            if (title.contains('contract') || title.contains('agreement')) { return 'CONTRACT'; }
            else if (title.contains('policy')) { return 'POLICY'; }
            else if (title.contains('report')) { return 'REPORT'; }
            else if (title.contains('invoice')) { return 'INVOICE'; }
        }
        String lowerContent = (content == null) ? '' : content.toLowerCase();
        if (lowerContent.contains('terms and conditions') || lowerContent.contains('liability')) {
            return 'LEGAL_DOCUMENT';
        } else if (lowerContent.contains('financial') || lowerContent.contains('budget')) {
            return 'FINANCIAL_DOCUMENT';
        } else if (lowerContent.contains('medical') || lowerContent.contains('health')) {
            return 'HEALTHCARE_DOCUMENT';
        }
        return 'GENERAL_DOCUMENT';
    }

    private static AIProcessingResponse callAIService(AIProcessingRequest request) {
        try {
            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint(AI_SERVICE_ENDPOINT + '/analyze');
            httpReq.setMethod('POST');
            httpReq.setHeader('Content-Type', 'application/json');
            httpReq.setTimeout(TIMEOUT_SECONDS * 1000);
            String requestBody = JSON.serialize(request);
            httpReq.setBody(requestBody);
            Http http = new Http();
            HttpResponse httpRes = http.send(httpReq);
            if (httpRes.getStatusCode() == 200) {
                AIProcessingResponse response = (AIProcessingResponse) JSON.deserialize(httpRes.getBody(), AIProcessingResponse.class);
                response.success = true;
                return response;
            } else {
                AIProcessingResponse errorResponse = new AIProcessingResponse();
                errorResponse.success = false;
                errorResponse.errorMessage = 'AI Service error: ' + httpRes.getStatus();
                return errorResponse;
            }
        } catch (Exception e) {
            System.debug('AI Service callout error: ' + e.getMessage());
            return performLocalAIProcessing(request);
        }
    }

    private static AIProcessingResponse performLocalAIProcessing(AIProcessingRequest request) {
        AIProcessingResponse response = new AIProcessingResponse();
        response.success = true;
        response.processingId = generateProcessingId();
        response.confidenceScore = 75;
        try {
            response.classification = classifyDocumentLocally(request.content);
            response.insights = generateLocalInsights(request.content, request.documentType);
            if (request.requestedAnalysis != null && request.requestedAnalysis.contains('compliance_analysis')) {
                response.complianceAnalysis = performLocalComplianceCheck(request.content);
            }
            if (request.requestedAnalysis != null && request.requestedAnalysis.contains('anomaly_detection')) {
                response.insights.addAll(detectLocalAnomaliesImpl(request.content));
            }
        } catch (Exception e) {
            response.success = false;
            response.errorMessage = 'Local AI processing failed: ' + e.getMessage();
        }
        return response;
    }

    private static AIProcessingResponse enhanceComplianceAnalysis(AIProcessingResponse response, List<String> regulations) {
        try {
            Map<String, Object> enhancedAnalysis = new Map<String, Object>();
            if (response != null && response.complianceAnalysis != null) {
                enhancedAnalysis.putAll(response.complianceAnalysis);
            }
            for (String regulation : regulations) {
                enhancedAnalysis.put(regulation + '_compliance', analyzeRegulationCompliance(regulation, response));
            }
            Integer overallScore = calculateComplianceScore(enhancedAnalysis);
            enhancedAnalysis.put('overallComplianceScore', overallScore);
            if (response != null) response.complianceAnalysis = enhancedAnalysis;
            return response;
        } catch (Exception e) {
            System.debug('Error enhancing compliance analysis: ' + e.getMessage());
            return response;
        }
    }

    private static AIProcessingResponse processAnomalyResults(AIProcessingResponse response) {
        try {
            List<AIInsight> processedInsights = new List<AIInsight>();
            if (response != null && response.insights != null) {
                for (AIInsight insight : response.insights) {
                    if (insight.type == 'anomaly') {
                        insight.severity = determineSeverity(insight.confidence);
                        insight.recommendations = generateAnomalyRecommendationsAsStrings(insight);
                    }
                    processedInsights.add(insight);
                }
                response.insights = processedInsights;
            }
            return response;
        } catch (Exception e) {
            System.debug('Error processing anomaly results: ' + e.getMessage());
            return response;
        }
    }

    private static void storeAIResults(String documentId, AIProcessingResponse response) {
        try {
            // Use Document_AI_Result__c as the canonical storage SObject for AI outputs.
            Document_AI_Result__c record = new Document_AI_Result__c();
            record.Processing_ID__c = response != null ? response.processingId : null;
            record.Classification__c = response != null ? response.classification : null;
            record.Confidence_Score__c = response != null ? response.confidenceScore : null;
            record.Processing_Date__c = System.now();
            record.Success__c = response != null ? response.success : false;
            record.AI_Analysis_Summary__c = response != null ? 'AI processing completed' : 'No response';
            if (response != null && response.insights != null && !response.insights.isEmpty()) {
                record.AI_Insights__c = JSON.serialize(response.insights);
            }
            if (response != null && response.complianceAnalysis != null && !response.complianceAnalysis.isEmpty()) {
                record.Compliance_Analysis__c = JSON.serialize(response.complianceAnalysis);
            }
            // Also store tags if available
            if (response != null && response.complianceAnalysis != null && response.complianceAnalysis.containsKey('tags')) {
                try {
                    Object tagsObj = response.complianceAnalysis.get('tags');
                    if (tagsObj instanceof List<Object>) {
                        List<Object> tagsList = (List<Object>) tagsObj;
                        List<String> sTags = new List<String>();
                        for (Object o : tagsList) sTags.add(String.valueOf(o));
                        record.Compliance_Tags__c = String.join(sTags, ',');
                    } else {
                        record.Compliance_Tags__c = String.valueOf(tagsObj);
                    }
                } catch (Exception ex) {
                    // ignore tags parsing errors
                }
            }
            // Safely insert and collect errors
            Database.SaveResult[] results = Database.insert(new List<SObject>{ record }, false);
            if (results != null && results.size() > 0 && !results[0].isSuccess()) {
                for (Database.Error err : results[0].getErrors()) {
                    System.debug('Document_AI_Result insert error: ' + err.getStatusCode() + ' - ' + err.getMessage());
                }
            }
        } catch (Exception e) {
            System.debug('Error storing AI results: ' + e.getMessage());
        }
    }

    private static void storeComplianceResults(String documentId, AIProcessingResponse response) {
        // We reuse storeAIResults for overall storage; keep this method for compatibility.
        storeAIResults(documentId, response);
    }

    private static void storeAnomalyResults(String documentId, AIProcessingResponse response) {
        // Rather than creating a separate AnomalyDetectionRecord__c SObject (which might not exist),
        // append anomaly insights into the main Document_AI_Result__c AI_Insights__c JSON.
        try {
            if (response == null || response.insights == null) return;
            // Build a short summary of anomalies and persist using same storage method
            List<AIInsight> anomalies = new List<AIInsight>();
            for (AIInsight ins : response.insights) {
                if (ins != null && 'anomaly'.equals(ins.type)) anomalies.add(ins);
            }
            if (!anomalies.isEmpty()) {
                // create a result record with anomalies serialized
                Document_AI_Result__c record = new Document_AI_Result__c();
                record.Processing_ID__c = response.processingId;
                record.Processing_Date__c = System.now();
                record.Success__c = response.success;
                record.AI_Insights__c = JSON.serialize(anomalies);
                Database.insert(record, false);
            }
        } catch (Exception e) {
            System.debug('Error storing anomaly results: ' + e.getMessage());
        }
    }

    // ------------------------------
    // Local AI processing helpers
    // ------------------------------
    private static String classifyDocumentLocally(String content) {
        String lowerContent = (content == null) ? '' : content.toLowerCase();
        if (lowerContent.contains('contract') || lowerContent.contains('agreement')) {
            return 'CONTRACT';
        } else if (lowerContent.contains('policy') || lowerContent.contains('procedure')) {
            return 'POLICY';
        } else if (lowerContent.contains('report') || lowerContent.contains('analysis')) {
            return 'REPORT';
        } else if (lowerContent.contains('invoice') || lowerContent.contains('billing')) {
            return 'FINANCIAL';
        }
        return 'GENERAL';
    }

    private static List<AIInsight> generateLocalInsights(String content, String documentType) {
        List<AIInsight> insights = new List<AIInsight>();
        String body = content == null ? '' : content;
        if (body.length() < 100) {
            AIInsight insight = new AIInsight();
            insight.type = 'content_quality';
            insight.category = 'completeness';
            insight.title = 'Document Appears Incomplete';
            insight.description = 'The document content is very short and may be incomplete.';
            insight.confidence = 85;
            insight.severity = 'MEDIUM';
            insight.recommendations.add('Review document for completeness');
            insights.add(insight);
        }

        if (documentType == 'CONTRACT') {
            insights.addAll(generateContractInsights(body));
        } else if (documentType == 'POLICY') {
            insights.addAll(generatePolicyInsights(body));
        } else if (documentType == 'FINANCIAL') {
            insights.addAll(generateFinancialInsights(body));
        }

        if (containsPII(body)) {
            AIInsight insight = new AIInsight();
            insight.type = 'privacy';
            insight.category = 'pii_detection';
            insight.title = 'Personal Information Detected';
            insight.description = 'Document contains potential personal identifiable information.';
            insight.confidence = 90;
            insight.severity = 'HIGH';
            insight.recommendations.add('Implement data protection measures');
            insight.recommendations.add('Review access permissions');
            insights.add(insight);
        }

        if (containsComplianceTerms(body)) {
            AIInsight insight = new AIInsight();
            insight.type = 'compliance';
            insight.category = 'regulatory_content';
            insight.title = 'Regulatory Content Identified';
            insight.description = 'Document contains compliance-related terminology requiring review.';
            insight.confidence = 80;
            insight.severity = 'MEDIUM';
            insight.recommendations.add('Verify compliance requirements');
            insight.recommendations.add('Review with legal team');
            insights.add(insight);
        }

        Map<String, Object> readabilityMetrics = calculateReadabilityMetrics(body);
        Integer score = (Integer)readabilityMetrics.get('readabilityScore');
        if (score < 50) {
            AIInsight insight = new AIInsight();
            insight.type = 'readability';
            insight.category = 'document_quality';
            insight.title = 'Low Readability Score';
            insight.description = 'Document may be difficult to read and understand.';
            insight.confidence = 75;
            insight.severity = 'LOW';
            insight.recommendations.add('Simplify complex sentences');
            insight.recommendations.add('Use clearer terminology');
            insights.add(insight);
        }
        return insights;
    }

    private static List<AIInsight> generateContractInsights(String content) {
        List<AIInsight> contractInsights = new List<AIInsight>();
        String lowerContent = (content == null) ? '' : content.toLowerCase();
        List<String> essentialElements = new List<String>{ 'consideration', 'parties', 'terms', 'conditions', 'obligations', 'termination', 'liability', 'governing law' };
        List<String> missingElements = new List<String>();
        for (String element : essentialElements) {
            if (!lowerContent.contains(element)) {
                missingElements.add(element);
            }
        }
        if (missingElements.size() > 2) {
            AIInsight insight = new AIInsight();
            insight.type = 'contract_quality';
            insight.category = 'completeness';
            insight.title = 'Missing Essential Contract Elements';
            insight.description = 'Contract appears to be missing key elements: ' + String.join(missingElements, ', ');
            insight.confidence = 85;
            insight.severity = 'HIGH';
            insight.recommendations.add('Review and add missing contract elements');
            insight.recommendations.add('Consult with legal counsel');
            contractInsights.add(insight);
        }

        if (!lowerContent.contains('termination') && !lowerContent.contains('end') && !lowerContent.contains('expire')) {
            AIInsight insight = new AIInsight();
            insight.type = 'contract_quality';
            insight.category = 'termination';
            insight.title = 'Missing Termination Clause';
            insight.description = 'Contract does not appear to have clear termination provisions.';
            insight.confidence = 80;
            insight.severity = 'MEDIUM';
            insight.recommendations.add('Add termination clause');
            insight.recommendations.add('Define exit conditions');
            contractInsights.add(insight);
        }
        return contractInsights;
    }

    private static List<AIInsight> generatePolicyInsights(String content) {
        List<AIInsight> policyInsights = new List<AIInsight>();
        String lowerContent = (content == null) ? '' : content.toLowerCase();
        List<String> policyElements = new List<String>{ 'purpose', 'scope', 'responsibilities', 'procedures', 'compliance', 'enforcement', 'review' };
        Integer foundElements = 0;
        for (String element : policyElements) {
            if (lowerContent.contains(element)) { foundElements++; }
        }
        if (foundElements < 4) {
            AIInsight insight = new AIInsight();
            insight.type = 'policy_quality';
            insight.category = 'structure';
            insight.title = 'Incomplete Policy Structure';
            insight.description = 'Policy may be missing key structural elements for effectiveness.';
            insight.confidence = 75;
            insight.severity = 'MEDIUM';
            insight.recommendations.add('Review policy structure');
            insight.recommendations.add('Add missing policy sections');
            policyInsights.add(insight);
        }

        if (!lowerContent.contains('review') && !lowerContent.contains('update') && !lowerContent.contains('revision')) {
            AIInsight insight = new AIInsight();
            insight.type = 'policy_quality';
            insight.category = 'maintenance';
            insight.title = 'Missing Review Provisions';
            insight.description = 'Policy lacks provisions for periodic review and updates.';
            insight.confidence = 85;
            insight.severity = 'MEDIUM';
            insight.recommendations.add('Add review schedule');
            insight.recommendations.add('Define update procedures');
            policyInsights.add(insight);
        }
        return policyInsights;
    }

    private static List<AIInsight> generateFinancialInsights(String content) {
        List<AIInsight> financialInsights = new List<AIInsight>();
        String lowerContent = (content == null) ? '' : content.toLowerCase();
        if (lowerContent.contains('audit') || lowerContent.contains('financial')) {
            if (!lowerContent.contains('internal controls') && !lowerContent.contains('sox')) {
                AIInsight insight = new AIInsight();
                insight.type = 'financial_compliance';
                insight.category = 'sox_compliance';
                insight.title = 'Potential SOX Compliance Gap';
                insight.description = 'Financial document may require SOX compliance considerations.';
                insight.confidence = 70;
                insight.severity = 'MEDIUM';
                insight.recommendations.add('Review SOX compliance requirements');
                insight.recommendations.add('Add internal controls documentation');
                financialInsights.add(insight);
            }
        }

        Pattern currencyPattern = Pattern.compile('\\$[\\d,]+\\.?\\d*|\\d+\\.\\d{2}');
        Matcher matcher = currencyPattern.matcher(content == null ? '' : content);
        Integer currencyCount = 0;
        while (matcher.find()) {
            currencyCount++;
        }
        if (currencyCount > 10) {
            AIInsight insight = new AIInsight();
            insight.type = 'financial_data';
            insight.category = 'data_protection';
            insight.title = 'High Volume of Financial Data';
            insight.description = 'Document contains numerous financial amounts requiring protection.';
            insight.confidence = 90;
            insight.severity = 'HIGH';
            insight.recommendations.add('Implement financial data protection');
            insight.recommendations.add('Review access controls');
            financialInsights.add(insight);
        }
        return financialInsights;
    }

    private static Boolean containsComplianceTerms(String content) {
        List<String> complianceTerms = new List<String>{ 'gdpr', 'hipaa', 'sox', 'ccpa', 'compliance', 'regulation', 'audit', 'privacy', 'data protection', 'security' };
        String lowerContent = (content == null) ? '' : content.toLowerCase();
        for (String term : complianceTerms) {
            if (lowerContent.contains(term)) { return true; }
        }
        return false;
    }

    private static Map<String, Object> calculateReadabilityMetrics(String content) {
        Map<String, Object> metrics = new Map<String, Object>();
        String cleaned = (content == null) ? '' : content;
        Integer sentenceCount = 0;
        Integer wordCount = 0;
        Integer syllableCount = 0;
        if (String.isNotBlank(cleaned)) {
            sentenceCount = Math.max(1, cleaned.split('[.!?]+').size());
            wordCount = Math.max(1, cleaned.split('\\s+').size());
            syllableCount = estimateSyllableCount(cleaned);
            Double avgSentenceLength = (Double)wordCount / sentenceCount;
            Double avgSyllablesPerWord = (Double)syllableCount / wordCount;
            Double readabilityScore = 206.835 - (1.015 * avgSentenceLength) - (84.6 * avgSyllablesPerWord);
            Integer scoreInt = Math.max(0, Math.min(100, readabilityScore.intValue()));
            metrics.put('readabilityScore', scoreInt);
            metrics.put('avgSentenceLength', Integer.valueOf(avgSentenceLength.intValue()));
            metrics.put('avgSyllablesPerWord', avgSyllablesPerWord);
            metrics.put('wordCount', wordCount);
            metrics.put('sentenceCount', sentenceCount);
        } else {
            metrics.put('readabilityScore', 50);
        }
        return metrics;
    }

    private static Integer estimateSyllableCount(String content) {
        Integer syllables = 0;
        String[] words = (content == null) ? new String[0] : content.toLowerCase().replaceAll('[^a-zA-Z\\s]', '').split('\\s+');
        for (String word : words) {
            if (word == null || word.length() == 0) continue;
            Integer wordSyllables = 1;
            Boolean previousWasVowel = false;
            for (Integer i = 0; i < word.length(); i++) {
                String letter = word.substring(i, i + 1);
                Boolean isVowel = 'aeiou'.contains(letter);
                if (isVowel && !previousWasVowel) {
                    wordSyllables++;
                }
                previousWasVowel = isVowel;
            }
            if (word.endsWith('e') && word.length() > 1) {
                wordSyllables--;
            }
            syllables += Math.max(1, wordSyllables);
        }
        return syllables;
    }

    private static Map<String, Object> performLocalComplianceCheck(String content) {
        Map<String, Object> analysis = new Map<String, Object>();
        String lowerContent = (content == null) ? '' : content.toLowerCase();
        Integer complianceScore = 100;
        if (lowerContent.contains('personal data') || lowerContent.contains('gdpr') || containsPII(content)) {
            if (!lowerContent.contains('consent') && !lowerContent.contains('data protection')) {
                complianceScore -= 20;
                analysis.put('GDPR_violations', 'Missing consent or data protection clauses');
            }
            analysis.put('GDPR_compliant', complianceScore >= 80);
        } else {
            analysis.put('GDPR_compliant', true);
        }

        if (lowerContent.contains('health') || lowerContent.contains('medical') || lowerContent.contains('patient')) {
            if (!lowerContent.contains('hipaa') && !lowerContent.contains('protected health information')) {
                complianceScore -= 25;
                analysis.put('HIPAA_violations', 'Missing HIPAA compliance clauses');
            }
            analysis.put('HIPAA_compliant', complianceScore >= 75);
        } else {
            analysis.put('HIPAA_compliant', true);
        }

        if (lowerContent.contains('financial') || lowerContent.contains('audit') || lowerContent.contains('internal controls')) {
            if (!lowerContent.contains('sox') && !lowerContent.contains('sarbanes-oxley')) {
                complianceScore -= 15;
                analysis.put('SOX_violations', 'Missing SOX compliance references');
            }
            analysis.put('SOX_compliant', complianceScore >= 85);
        } else {
            analysis.put('SOX_compliant', true);
        }

        if (lowerContent.contains('california') || lowerContent.contains('ccpa') || (containsPII(content) && lowerContent.contains('consumer'))) {
            if (!lowerContent.contains('right to delete') && !lowerContent.contains('opt-out')) {
                complianceScore -= 20;
                analysis.put('CCPA_violations', 'Missing CCPA consumer rights clauses');
            }
            analysis.put('CCPA_compliant', complianceScore >= 80);
        } else {
            analysis.put('CCPA_compliant', true);
        }

        analysis.put('overallComplianceScore', Math.max(complianceScore, 0));
        return analysis;
    }

    private static List<AIInsight> detectLocalAnomaliesImpl(String content) {
        List<AIInsight> anomalies = new List<AIInsight>();
        String lower = (content == null) ? '' : content.toLowerCase();
        if (lower.contains('unauthorized') || lower.contains('breach') || lower.contains('exposed')) {
            AIInsight insight = new AIInsight();
            insight.type = 'anomaly';
            insight.category = 'security';
            insight.title = 'Potential Security Anomaly';
            insight.description = 'Language in the document indicates possible security incidents or exposures.';
            insight.confidence = 85;
            insight.severity = 'HIGH';
            insight.recommendations.add('Review security incidents reported in the document');
            anomalies.add(insight);
        }
        if (lower.contains('error') && lower.contains('stacktrace')) {
            AIInsight insight = new AIInsight();
            insight.type = 'anomaly';
            insight.category = 'technical';
            insight.title = 'Technical Error Artifacts';
            insight.description = 'Document contains error/stacktrace artifacts that might indicate sensitive runtime information.';
            insight.confidence = 75;
            insight.severity = 'MEDIUM';
            insight.recommendations.add('Sanitize logs and stack traces');
            anomalies.add(insight);
        }

    Pattern suspiciousPattern = Pattern.compile('(?i)\\b(alert|critical|severe)\\b|\\b(password|ssn|credit card)\\b');
        Matcher m = suspiciousPattern.matcher(content == null ? '' : content);
        if (m.find()) {
            AIInsight insight = new AIInsight();
            insight.type = 'anomaly';
            insight.category = 'suspicious_terms';
            insight.title = 'Suspicious Terms Detected';
            insight.description = 'High-risk terms detected (passwords, SSN, credit card, alert, critical).';
            insight.confidence = 80;
            insight.severity = 'HIGH';
            insight.recommendations.add('Review sensitive terms and redact if necessary');
            anomalies.add(insight);
        }
        return anomalies;
    }

    private static Map<String, Object> analyzeRegulationCompliance(String regulation, AIProcessingResponse response) {
        Map<String, Object> out = new Map<String, Object>();
        try {
            if (response == null || response.complianceAnalysis == null) {
                out.put('compliant', false);
                out.put('notes', 'No analysis available');
                return out;
            }
            if (response.complianceAnalysis.containsKey('overallComplianceScore')) {
                Object o = response.complianceAnalysis.get('overallComplianceScore');
                Integer score = 0;
                if (o instanceof Integer) score = (Integer)o;
                else if (o instanceof Decimal) score = ((Decimal)o).intValue();
                else {
                    try { score = Integer.valueOf(String.valueOf(o)); } catch (Exception ex) { score = 0; }
                }
                out.put('compliant', score >= 80);
                out.put('score', score);
                out.put('regulation', regulation);
            } else {
                String r = regulation == null ? '' : regulation.toLowerCase();
                if (r.contains('gdpr')) {
                    out.put('compliant', response.complianceAnalysis.containsKey('GDPR_compliant') ? response.complianceAnalysis.get('GDPR_compliant') : false);
                } else if (r.contains('hipaa')) {
                    out.put('compliant', response.complianceAnalysis.containsKey('HIPAA_compliant') ? response.complianceAnalysis.get('HIPAA_compliant') : false);
                } else {
                    out.put('compliant', false);
                }
                out.put('notes', 'Heuristic evaluation applied');
            }
        } catch (Exception e) {
            out.put('compliant', false);
            out.put('error', e.getMessage());
        }
        return out;
    }

    private static Integer calculateComplianceScore(Map<String, Object> analysis) {
        try {
            if (analysis == null) return 0;
            if (analysis.containsKey('overallComplianceScore')) {
                Object o = analysis.get('overallComplianceScore');
                if (o instanceof Integer) return (Integer)o;
                if (o instanceof Decimal) return ((Decimal)o).intValue();
                try { return Integer.valueOf(String.valueOf(o)); } catch (Exception ex) { return 0; }
            }
            Integer score = 100;
            if (analysis.containsKey('GDPR_compliant') && !(Boolean)analysis.get('GDPR_compliant')) score -= 20;
            if (analysis.containsKey('HIPAA_compliant') && !(Boolean)analysis.get('HIPAA_compliant')) score -= 20;
            if (analysis.containsKey('SOX_compliant') && !(Boolean)analysis.get('SOX_compliant')) score -= 15;
            if (analysis.containsKey('CCPA_compliant') && !(Boolean)analysis.get('CCPA_compliant')) score -= 20;
            return Math.max(score, 0);
        } catch (Exception e) {
            System.debug('calculateComplianceScore error: ' + e.getMessage());
            return 0;
        }
    }

    private static List<String> generateAnomalyRecommendationsAsStrings(AIInsight insight) {
        List<String> recs = new List<String>();
        if (insight == null) return recs;
        if (insight.category == 'security') {
            recs.add('Investigate security incidents and escalate to SOC');
            recs.add('Perform access review for affected documents');
        } else if (insight.category == 'technical') {
            recs.add('Remove stack traces and error dumps');
            recs.add('Redact runtime environment details');
        } else {
            recs.add('Review flagged content');
        }
        return recs;
    }

    private static String determineSeverity(Integer confidence) {
        if (confidence == null) return 'MEDIUM';
        if (confidence >= 85) return 'CRITICAL';
        if (confidence >= 70) return 'HIGH';
        if (confidence >= 40) return 'MEDIUM';
        return 'LOW';
    }

    // --------------------------
    // Small utility / stubbed IO
    // --------------------------
    private static Boolean isTextFile(String fileExtension) {
        return fileExtension == 'txt' || fileExtension == 'md' || fileExtension == 'csv' || fileExtension == 'json' || fileExtension == 'text';
    }

    private static String extractPDFText(Blob b) {
        // Placeholder - replace with real extraction integration
        return '';
    }

    private static String extractWordText(Blob b) {
        // Placeholder - replace with real extraction integration
        return '';
    }

    private static Boolean containsPII(String content) {
        if (String.isBlank(content)) return false;
        Pattern emailPat = Pattern.compile('[A-Za-z0-9.%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}');
        if (emailPat.matcher(content).find()) return true;
        Pattern ssnPat = Pattern.compile('\\b\\d{3}[-\\s]?\\d{2}[-\\s]?\\d{4}\\b');
        if (ssnPat.matcher(content).find()) return true;
        Pattern ccPat = Pattern.compile('\\b(?:\\d[ -]?){13,16}\\b');
        if (ccPat.matcher(content).find()) return true;
        Pattern phonePat = Pattern.compile('\\+?\\d[\\d\\s\\-()]{6,}\\d');
        if (phonePat.matcher(content).find()) return true;
        return false;
    }

    private static String generateProcessingId() {
        return String.valueOf(DateTime.now().getTime());
    }
}