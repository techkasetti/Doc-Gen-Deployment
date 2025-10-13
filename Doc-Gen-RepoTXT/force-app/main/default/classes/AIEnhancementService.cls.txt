public with sharing class AIEnhancementService {
    
    private static final String AI_SERVICE_ENDPOINT = 'callout:AnARA_AI_Service';
    private static final Integer TIMEOUT_SECONDS = 30;
    
    public class AIProcessingRequest {
        @AuraEnabled
        public String documentId { get; set; }
        @AuraEnabled
        public String content { get; set; }
        @AuraEnabled
        public String documentType { get; set; }
        @AuraEnabled
        public List<String> requestedAnalysis { get; set; }
        @AuraEnabled
        public Map<String, String> metadata { get; set; }
        
        public AIProcessingRequest() {
            this.requestedAnalysis = new List<String>();
            this.metadata = new Map<String, String>();
        }
    }
    
    public class AIProcessingResponse {
        @AuraEnabled
        public String processingId { get; set; }
        @AuraEnabled
        public Boolean success { get; set; }
        @AuraEnabled
        public String classification { get; set; }
        @AuraEnabled
        public List<AIInsight> insights { get; set; }
        @AuraEnabled
        public Map<String, Object> complianceAnalysis { get; set; }
        @AuraEnabled
        public List<String> suggestedClauses { get; set; }
        @AuraEnabled
        public Integer confidenceScore { get; set; }
        @AuraEnabled
        public String errorMessage { get; set; }
        
        public AIProcessingResponse() {
            this.insights = new List<AIInsight>();
            this.suggestedClauses = new List<String>();
            this.complianceAnalysis = new Map<String, Object>();
        }
    }
    
    public class AIInsight {
        @AuraEnabled
        public String type { get; set; }
        @AuraEnabled
        public String category { get; set; }
        @AuraEnabled
        public String title { get; set; }
        @AuraEnabled
        public String description { get; set; }
        @AuraEnabled
        public Integer confidence { get; set; }
        @AuraEnabled
        public String severity { get; set; }
        @AuraEnabled
        public List<String> recommendations { get; set; }
        @AuraEnabled
        public Map<String, String> metadata { get; set; }
        
        public AIInsight() {
            this.recommendations = new List<String>();
            this.metadata = new Map<String, String>();
        }
    }
    
    @AuraEnabled
    public static AIProcessingResponse enhanceDocument(String documentId, List<String> enhancementTypes) {
        try {
            ContentVersion document = getDocumentContent(documentId);
            if (document == null) {
                throw new AnaraException('Document not found');
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
            
            if (response.success) {
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
    
    @AuraEnabled
    public static AIProcessingResponse analyzeCompliance(String documentId, List<String> regulations) {
        try {
            ContentVersion document = getDocumentContent(documentId);
            if (document == null) {
                throw new AnaraException('Document not found');
            }
            
            AIProcessingRequest request = new AIProcessingRequest();
            request.documentId = documentId;
            request.content = extractDocumentText(document);
            request.requestedAnalysis = new List<String>{'compliance_analysis'};
            request.metadata.put('regulations', String.join(regulations, ','));
            request.metadata.put('analysisType', 'REGULATORY_COMPLIANCE');
            
            AIProcessingResponse response = callAIService(request);
            response = enhanceComplianceAnalysis(response, regulations);
            
            if (response.success) {
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


@AuraEnabled
public static List<String> generateClauseSuggestions(String documentId, String clauseType, String jurisdiction) {
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
        
        if (response.success && response.suggestedClauses != null) {
            return response.suggestedClauses;
        }
        
        return new List<String>();
    } catch (Exception e) {
        System.debug('Error generating clause suggestions: ' + e.getMessage());
        return new List<String>();
    }
}

@AuraEnabled
public static Map<String, Object> performSemanticAnalysis(String documentId, String query) {
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
        result.put('success', response.success);
        result.put('results', response.complianceAnalysis);
        result.put('confidence', response.confidenceScore);
        
        if (response.insights != null && !response.insights.isEmpty()) {
            result.put('insights', response.insights);
        }
        
        return result;
    } catch (Exception e) {
        return new Map<String, Object>{'success' => false, 'error' => e.getMessage()};
    }
}
@AuraEnabled
public static AIProcessingResponse detectAnomalies(String documentId) {
    try {
        ContentVersion document = getDocumentContent(documentId);
        if (document == null) {
            throw new AnaraException('Document not found');
        }
        
        AIProcessingRequest request = new AIProcessingRequest();
        request.documentId = documentId;
        request.content = extractDocumentText(document);
        request.requestedAnalysis = new List<String>{'anomaly_detection', 'risk_assessment'};
        request.metadata.put('detectionType', 'COMPREHENSIVE');
        request.metadata.put('riskThreshold', '0.7');
        request.metadata.put('includePatterns', 'true');
        
        AIProcessingResponse response = callAIService(request);
        
        // Enhanced anomaly processing
        if (response.success) {
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

@AuraEnabled
public static Map<String, Object> generateExecutiveSummary(String documentId, String summaryType) {
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
        result.put('success', response.success);
        if (response.success) {
            result.put('summary', response.complianceAnalysis.get('summary'));
            result.put('keyPoints', response.complianceAnalysis.get('keyPoints'));
            result.put('recommendations', response.suggestedClauses);
            result.put('riskLevel', response.complianceAnalysis.get('riskLevel'));
        } else {
            result.put('error', response.errorMessage);
        }
        
        return result;
        
    } catch (Exception e) {
        return new Map<String, Object>{'success' => false, 'error' => e.getMessage()};
    }
}

@future
public static void processDocumentBatch(List<String> documentIds, String analysisType) {
    for (String docId : documentIds) {
        try {
            List<String> analysisTypes = new List<String>{analysisType};
            enhanceDocument(docId, analysisTypes);
        } catch (Exception e) {
            System.debug('Error processing document ' + docId + ': ' + e.getMessage());
        }
    }
}

// Private helper methods
private static ContentVersion getDocumentContent(String documentId) {
    try {
        return [
            SELECT Id, Title, FileExtension, ContentSize, VersionData, 
                   CreatedDate, ContentDocumentId, Description
            FROM ContentVersion 
            WHERE ContentDocumentId = :documentId 
            AND IsLatest = true 
            LIMIT 1
        ];
    } catch (Exception e) {
        System.debug('Error retrieving document: ' + e.getMessage());
        return null;
    }
}

private static String extractDocumentText(ContentVersion document) {
    try {
        if (document.VersionData == null) {
            return '';
        }
        
        String fileExtension = document.FileExtension?.toLowerCase();
        
        // Handle different file types
        if (isTextFile(fileExtension)) {
            return document.VersionData.toString();
        } else if (fileExtension == 'pdf') {
            return extractPDFText(document.VersionData);
        } else if (fileExtension == 'docx' || fileExtension == 'doc') {
            return extractWordText(document.VersionData);
        } else {
            // For unsupported formats, return metadata
            return 'Title: ' + document.Title + '\nFile Type: ' + fileExtension;
        }
        
    } catch (Exception e) {
        System.debug('Error extracting text: ' + e.getMessage());
        return 'TEXT_EXTRACTION_ERROR';
    }
}

private static String determineDocumentType(ContentVersion document) {
    String content = extractDocumentText(document);
    String title = document.Title?.toLowerCase();
    
    // AI-powered document type classification
    if (title != null) {
        if (title.contains('contract') || title.contains('agreement')) {
            return 'CONTRACT';
        } else if (title.contains('policy')) {
            return 'POLICY';
        } else if (title.contains('report')) {
            return 'REPORT';
        } else if (title.contains('invoice')) {
            return 'INVOICE';
        }
    }
    
    // Content-based classification
    String lowerContent = content.toLowerCase();
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
        // Prepare HTTP request
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint(AI_SERVICE_ENDPOINT + '/analyze');
        httpReq.setMethod('POST');
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setTimeout(TIMEOUT_SECONDS * 1000);
        
        // Serialize request
        String requestBody = JSON.serialize(request);
        httpReq.setBody(requestBody);
        
        // Make callout
        Http http = new Http();
        HttpResponse httpRes = http.send(httpReq);
        
        if (httpRes.getStatusCode() == 200) {
            AIProcessingResponse response = (AIProcessingResponse) JSON.deserialize(
                httpRes.getBody(), AIProcessingResponse.class
                );
            response.success = true;
            return response;
        } else {
            // Handle error response
            AIProcessingResponse errorResponse = new AIProcessingResponse();
            errorResponse.success = false;
            errorResponse.errorMessage = 'AI Service error: ' + httpRes.getStatus();
            return errorResponse;
        }
        
    } catch (Exception e) {
        System.debug('AI Service callout error: ' + e.getMessage());
        
        // Fallback to local processing
        return performLocalAIProcessing(request);
    }
}

private static AIProcessingResponse performLocalAIProcessing(AIProcessingRequest request) {
    AIProcessingResponse response = new AIProcessingResponse();
    response.success = true;
    response.processingId = generateProcessingId();
    response.confidenceScore = 75; // Default confidence for local processing
    
    try {
        // Local document classification
        response.classification = classifyDocumentLocally(request.content);
        
        // Generate basic insights
        response.insights = generateLocalInsights(request.content, request.documentType);
        
        // Basic compliance analysis
        if (request.requestedAnalysis.contains('compliance_analysis')) {
            response.complianceAnalysis = performLocalComplianceCheck(request.content);
        }
        
        // Anomaly detection
        if (request.requestedAnalysis.contains('anomaly_detection')) {
            response.insights.addAll(detectLocalAnomalies(request.content));
        }
        
    } catch (Exception e) {
        response.success = false;
        response.errorMessage = 'Local AI processing failed: ' + e.getMessage();
    }
    
    return response;
}

private static AIProcessingResponse enhanceComplianceAnalysis(AIProcessingResponse response, List<String> regulations) {
    try {
        Map<String, Object> enhancedAnalysis = new Map<String, Object>(response.complianceAnalysis);
        
        // Add regulation-specific analysis
        for (String regulation : regulations) {
            enhancedAnalysis.put(regulation + '_compliance', analyzeRegulationCompliance(regulation, response));
        }
        
        // Calculate overall compliance score
        Integer overallScore = calculateComplianceScore(enhancedAnalysis);
        enhancedAnalysis.put('overallComplianceScore', overallScore);
        
        response.complianceAnalysis = enhancedAnalysis;
        
        return response;
        
    } catch (Exception e) {
        System.debug('Error enhancing compliance analysis: ' + e.getMessage());
        return response;
    }
}

private static AIProcessingResponse processAnomalyResults(AIProcessingResponse response) {
    try {
        // Process and categorize anomalies
        List<AIInsight> processedInsights = new List<AIInsight>();
        
        for (AIInsight insight : response.insights) {
            if (insight.type == 'anomaly') {
                insight.severity = determineSeverity(insight.confidence);
                insight.recommendations = generateAnomalyRecommendations(insight);
            }
            processedInsights.add(insight);
        }
        
        response.insights = processedInsights;
        
        return response;
        
    } catch (Exception e) {
        System.debug('Error processing anomaly results: ' + e.getMessage());
        return response;
    }
}

private static void storeAIResults(String documentId, AIProcessingResponse response) {
    try {
        AIProcessingResult__c result = new AIProcessingResult__c();
        result.Document_ID__c = documentId;
        result.Processing_ID__c = response.processingId;
        result.Classification__c = response.classification;
        result.Confidence_Score__c = response.confidenceScore;
        result.Processing_Date__c = System.now();
        result.Success__c = response.success;
        
        // Serialize insights
        if (response.insights != null && !response.insights.isEmpty()) {
            result.AI_Insights__c = JSON.serialize(response.insights);
        }
        
        // Store compliance analysis
        if (response.complianceAnalysis != null && !response.complianceAnalysis.isEmpty()) {
            result.Compliance_Analysis__c = JSON.serialize(response.complianceAnalysis);
        }
        
        insert result;
        
    } catch (Exception e) {
        System.debug('Error storing AI results: ' + e.getMessage());
    }
}

private static void storeComplianceResults(String documentId, AIProcessingResponse response) {
    try {
        DocumentComplianceTracking__c compliance = new DocumentComplianceTracking__c();
        compliance.Document_ID__c = documentId;
        compliance.AI_Classification__c = response.classification;
        compliance.Analysis_Date__c = System.now();
        
        // Extract compliance scores
        if (response.complianceAnalysis.containsKey('overallComplianceScore')) {
            compliance.Compliance_Score__c = (Integer) response.complianceAnalysis.get('overallComplianceScore');
        }
        
        if (response.complianceAnalysis.containsKey('GDPR_compliance')) {
            Map<String, Object> gdprAnalysis = (Map<String, Object>) response.complianceAnalysis.get('GDPR_compliance');
            compliance.GDPR_Compliant__c = (Boolean) gdprAnalysis.get('compliant');
        }
        
        if (response.complianceAnalysis.containsKey('HIPAA_compliance')) {
            Map<String, Object> hipaaAnalysis = (Map<String, Object>) response.complianceAnalysis.get('HIPAA_compliance');
            compliance.HIPAA_Compliant__c = (Boolean) hipaaAnalysis.get('compliant');
        }
        
        upsert compliance Document_ID__c;
        
    } catch (Exception e) {
        System.debug('Error storing compliance results: ' + e.getMessage());
    }
}

private static void storeAnomalyResults(String documentId, AIProcessingResponse response) {
    try {
        List<AnomalyDetectionRecord__c> anomalyRecords = new List<AnomalyDetectionRecord__c>();
        
        for (AIInsight insight : response.insights) {
            if (insight.type == 'anomaly') {
                AnomalyDetectionRecord__c anomaly = new AnomalyDetectionRecord__c();
                anomaly.Document__c = documentId;
                anomaly.Anomaly_Type__c = insight.category;
                anomaly.Description__c = insight.description;
                anomaly.Severity__c = insight.severity;
                anomaly.Confidence_Score__c = insight.confidence;
                anomaly.Detection_Date__c = System.now();
                anomalyRecords.add(anomaly);
            }
        }
        
        if (!anomalyRecords.isEmpty()) {
            insert anomalyRecords;
        }
        
    } catch (Exception e) {
        System.debug('Error storing anomaly results: ' + e.getMessage());
    }
}

// Local AI processing methods
private static String classifyDocumentLocally(String content) {
    String lowerContent = content.toLowerCase();
    
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
    
    // Basic content analysis
    if (content.length() < 100) {
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
    
    // Document type specific insights
    if (documentType == 'CONTRACT') {
        insights.addAll(generateContractInsights(content));
    } else if (documentType == 'POLICY') {
        insights.addAll(generatePolicyInsights(content));
    } else if (documentType == 'FINANCIAL') {
        insights.addAll(generateFinancialInsights(content));
    }
    
    // Check for sensitive information
    if (containsPII(content)) {
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
    
    // Check for compliance keywords
    if (containsComplianceTerms(content)) {
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
    
    // Language and readability insights
    Map<String, Object> readabilityMetrics = calculateReadabilityMetrics(content);
    if ((Integer) readabilityMetrics.get('readabilityScore') < 50) {
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
    String lowerContent = content.toLowerCase();
    
    // Check for essential contract elements
    List<String> essentialElements = new List<String>{
        'consideration', 'parties', 'terms', 'conditions',
        'obligations', 'termination', 'liability', 'governing law'
    };
    
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
    
    // Check for termination clauses
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
    String lowerContent = content.toLowerCase();
    
    // Check for policy structure elements
    List<String> policyElements = new List<String>{
        'purpose', 'scope', 'responsibilities', 'procedures',
        'compliance', 'enforcement', 'review'
    };
    
    Integer foundElements = 0;
    for (String element : policyElements) {
        if (lowerContent.contains(element)) {
            foundElements++;
        }
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
    
    // Check for review and update provisions
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
    String lowerContent = content.toLowerCase();
    
    // Check for financial document elements
    if (lowerContent.contains('audit') || lowerContent.contains('financial')) {
        // Check for SOX compliance indicators
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
    
    // Check for currency and amount patterns
    Pattern currencyPattern = Pattern.compile('\\$[\\d,]+\\.?\\d*|\\d+\\.\\d{2}');
    Matcher matcher = currencyPattern.matcher(content);
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
    List<String> complianceTerms = new List<String>{
        'gdpr', 'hipaa', 'sox', 'ccpa', 'compliance', 'regulation',
        'audit', 'privacy', 'data protection', 'security'
    };
    
    String lowerContent = content.toLowerCase();
    for (String term : complianceTerms) {
        if (lowerContent.contains(term)) {
            return true;
        }
    }
    return false;
}

private static Map<String, Object> calculateReadabilityMetrics(String content) {
    Map<String, Object> metrics = new Map<String, Object>();
    
    // Basic readability calculation (simplified Flesch Reading Ease)
    Integer sentenceCount = content.split('[.!?]+').size();
    Integer wordCount = content.split('\\s+').size();
    Integer syllableCount = estimateSyllableCount(content);
    
    if (sentenceCount > 0 && wordCount > 0) {
        Double avgSentenceLength = (Double) wordCount / sentenceCount;
        Double avgSyllablesPerWord = (Double) syllableCount / wordCount;
        
        // Simplified Flesch Reading Ease score
        Double readabilityScore = 206.835 - (1.015 * avgSentenceLength) - (84.6 * avgSyllablesPerWord);
        
        metrics.put('readabilityScore', Math.max(0, Math.min(100, readabilityScore.intValue())));
        metrics.put('avgSentenceLength', avgSentenceLength.intValue());
        metrics.put('avgSyllablesPerWord', avgSyllablesPerWord);
        metrics.put('wordCount', wordCount);
        metrics.put('sentenceCount', sentenceCount);
    } else {
        metrics.put('readabilityScore', 50); // Default neutral score
    }
    
    return metrics;
}

private static Integer estimateSyllableCount(String content) {
    // Simplified syllable counting
    Integer syllables = 0;
    String[] words = content.toLowerCase().replaceAll('[^a-zA-Z\\s]', '').split('\\s+');
    
    for (String word : words) {
        if (word.length() > 0) {
            Integer wordSyllables = 1; // Minimum 1 syllable per word
            
            // Count vowel groups as syllables (simplified)
            Boolean previousWasVowel = false;
            for (Integer i = 0; i < word.length(); i++) {
                String letter = word.substring(i, i + 1);
                Boolean isVowel = 'aeiou'.contains(letter);
                
                if (isVowel && !previousWasVowel) {
                    wordSyllables++;
                }
                previousWasVowel = isVowel;
            }
            
            // Adjust for silent e
            if (word.endsWith('e') && word.length() > 1) {
                wordSyllables--;
            }
            
            syllables += Math.max(1, wordSyllables);
        }
    }
    
    return syllables;
}

// Continue with the remaining helper methods...
private static Map<String, Object> performLocalComplianceCheck(String content) {
    Map<String, Object> analysis = new Map<String, Object>();
    String lowerContent = content.toLowerCase();
    Integer complianceScore = 100;
    
    // Basic GDPR check
    if (lowerContent.contains('personal data') || lowerContent.contains('gdpr') || containsPII(content)) {
        if (!lowerContent.contains('consent') && !lowerContent.contains('data protection')) {
            complianceScore -= 20;
            analysis.put('GDPR_violations', 'Missing consent or data protection clauses');
        }
        analysis.put('GDPR_compliant', complianceScore >= 80);
    } else {
        analysis.put('GDPR_compliant', true); // No personal data, compliant by default
    }
    
    // Basic HIPAA check
    if (lowerContent.contains('health') || lowerContent.contains('medical') || lowerContent.contains('patient')) {
        if (!lowerContent.contains('hipaa') && !lowerContent.contains('protected health information')) {
            complianceScore -= 25;
            analysis.put('HIPAA_violations', 'Missing HIPAA compliance clauses');
        }
        analysis.put('HIPAA_compliant', complianceScore >= 75);
    } else {
        analysis.put('HIPAA_compliant', true);
    }
    
    // Basic SOX check
    if (lowerContent.contains('financial') || lowerContent.contains('audit') || lowerContent.contains('internal controls')) {
        if (!lowerContent.contains('sox') && !lowerContent.contains('sarbanes-oxley')) {
            complianceScore -= 15;
            analysis.put('SOX_violations', 'Missing SOX compliance references');
        }
        analysis.put('SOX_compliant', complianceScore >= 85);
    } else {
        analysis.put('SOX_compliant', true);
    }
    
    // Basic CCPA check
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
}