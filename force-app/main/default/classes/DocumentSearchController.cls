/**
* @description Advanced Document Search Controller with AI-powered search capabilities
* @author Anara AI Development Team
* @version 1.0
*/
public with sharing class DocumentSearchController {
    
    
    public static List<Id> searchDocuments(String q) {
        List<Id> out = new List<Id>();
        if (String.isBlank(q)) return out;
        if (!Schema.getGlobalDescribe().containsKey('Document__c')) return out;
        List<Document__c> rows = [SELECT Id FROM Document__c LIMIT 10];
        for (Document__c d : rows) out.add(d.Id);
        return out;
    }
    @AuraEnabled(cacheable=true)
    public static List<DocumentSearchResult> searchDocuments(Map<String, Object> searchParams) {
        try {
            String searchTerm = (String) searchParams.get('searchTerm');
            Map<String, Object> filters = (Map<String, Object>) searchParams.get('filters');
            
            // Build dynamic SOQL query
            String query = buildSearchQuery(searchTerm, filters);
            
            // Execute search
            List<ContentDocument> documents = Database.query(query);
            
            // Convert to search results
            List<DocumentSearchResult> results = convertToSearchResults(documents, searchTerm);
            
            // Apply AI-powered ranking if AI query is provided
            if (filters!= null && filters.containsKey('aiQuery') && filters.get('aiQuery')!= null) {
                String aiQuery = (String) filters.get('aiQuery');
                results = applyAIRanking(results, aiQuery);
            }
            
            return results;
            
        } catch (Exception e) {
            throw new AuraHandledException('Search failed: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getFilterOptions() {
        try {
            Map<String, Object> options = new Map<String, Object>();
            
            // Get available file types
            List<String> fileTypes = getAvailableFileTypes();
            options.put('fileTypes', fileTypes);
            
            // Get compliance statistics
            Map<String, Integer> complianceStats = getComplianceStatistics();
            options.put('complianceStats', complianceStats);
            
            return options;
            
        } catch (Exception e) {
            throw new AuraHandledException('Failed to load filter options: ' + e.getMessage());
        }
    }
    
    private static String buildSearchQuery(String searchTerm, Map<String, Object> filters) {
        List<String> queryParts = new List<String>();
        List<String> conditions = new List<String>();
        
        // Base query
        queryParts.add('SELECT Id, Title, FileExtension, ContentSize, CreatedDate, LastModifiedDate, CreatedBy.Name');
        queryParts.add('FROM ContentDocument');
        
        // Search term condition
        if (String.isNotBlank(searchTerm)) {
            String escapedSearchTerm = String.escapeSingleQuotes(searchTerm);
            conditions.add('(Title LIKE \'%' + escapedSearchTerm + '%\' OR FileExtension LIKE \'%' + escapedSearchTerm + '%\')');
        }
        
        // Apply filters
        if (filters!= null) {
            // Date range filters
            if (filters.containsKey('createdFromDate') && filters.get('createdFromDate')!= null) {
                Date fromDate = Date.valueOf((String) filters.get('createdFromDate'));
                conditions.add('CreatedDate >= ' + fromDate.format());
            }
            
            if (filters.containsKey('createdToDate') && filters.get('createdToDate')!= null) {
                Date toDate = Date.valueOf((String) filters.get('createdToDate'));
                conditions.add('CreatedDate <= ' + toDate.format());
            }
            
            // File type filter
            if (filters.containsKey('fileType') && String.isNotBlank((String) filters.get('fileType'))) {
                String fileType = String.escapeSingleQuotes((String) filters.get('fileType'));
                conditions.add('FileExtension = \'' + fileType + '\'');
            }
            
            // File size filter
            if (filters.containsKey('fileSize') && String.isNotBlank((String) filters.get('fileSize'))) {
                String sizeFilter = (String) filters.get('fileSize');
                String sizeCondition = buildFileSizeCondition(sizeFilter);
                if (String.isNotBlank(sizeCondition)) {
                    conditions.add(sizeCondition);
                }
            }
        }
        
        // Add WHERE clause if there are conditions
        if (!conditions.isEmpty()) {
            queryParts.add('WHERE ' + String.join(conditions, ' AND '));
        }
        
        // Add ORDER BY
        queryParts.add('ORDER BY LastModifiedDate DESC');
        
        // Add LIMIT
        queryParts.add('LIMIT 100');
        
        return String.join(queryParts, ' ');
    }
    
    private static String buildFileSizeCondition(String sizeFilter) {
        switch on sizeFilter {
            when 'small' {
                return 'ContentSize < 1048576'; // < 1MB
            }
            when 'medium' {
                return 'ContentSize >= 1048576 AND ContentSize < 10485760'; // 1-10MB
            }
            when 'large' {
                return 'ContentSize >= 10485760 AND ContentSize < 104857600'; // 10-100MB
            }
            when 'xlarge' {
                return 'ContentSize >= 104857600'; // > 100MB
            }
            when else {
                return '';
            }
        }
    }
    
    private static List<DocumentSearchResult> convertToSearchResults(List<ContentDocument> documents, String searchTerm) {
        List<DocumentSearchResult> results = new List<DocumentSearchResult>();
        
        // Get compliance data for all documents
        Map<Id, DocumentComplianceTracking__c> complianceMap = getComplianceDataMap(
            new List<Id>(new Map<Id, ContentDocument>(documents).keySet())
        );
        
        for (ContentDocument doc : documents) {
            DocumentSearchResult result = new DocumentSearchResult();
            result.documentId = doc.Id;
            result.title = doc.Title;
            result.fileExtension = doc.FileExtension;
            result.contentSize = doc.ContentSize;
            result.createdDate = doc.CreatedDate;
            result.lastModifiedDate = doc.LastModifiedDate;
            result.createdBy = doc.CreatedBy.Name;
            
            // Add compliance data
            if (complianceMap.containsKey(doc.Id)) {
                DocumentComplianceTracking__c compliance = complianceMap.get(doc.Id);
                result.complianceScore = Decimal.valueOf(compliance.Compliance_Score__c);
                result.gdprCompliant = Boolean.valueOf(compliance.GDPR_Compliant__c);
                result.hipaaCompliant = Boolean.valueOf(compliance.HIPAA_Compliant__c);
            }
            
            // Calculate relevance score
            result.relevanceScore = calculateRelevanceScore(doc, searchTerm);
            
            results.add(result);
        }
        
        return results;
    }
    
    private static Map<Id, DocumentComplianceTracking__c> getComplianceDataMap(List<Id> documentIds) {
        Map<Id, DocumentComplianceTracking__c> complianceMap = new Map<Id, DocumentComplianceTracking__c>();
        
        for (DocumentComplianceTracking__c compliance : [
            SELECT Document_ID__c, Compliance_Score__c, GDPR_Compliant__c, HIPAA_Compliant__c
            FROM DocumentComplianceTracking__c
            WHERE Document_ID__c IN :documentIds
            ORDER BY Analysis_Date__c DESC
        ]) {
            if (!complianceMap.containsKey(compliance.Document_ID__c)) {
                complianceMap.put(compliance.Document_ID__c, compliance);
            }
        }
        
        return complianceMap;
    }
    
    private static Decimal calculateRelevanceScore(ContentDocument doc, String searchTerm) {
        if (String.isBlank(searchTerm)) return 50.0;
        
        Decimal score = 0.0;
        String titleLower = doc.Title.toLowerCase();
        String searchLower = searchTerm.toLowerCase();
        
        // Exact match in title gets highest score
        if (titleLower.equals(searchLower)) {
            score += 100.0;
        } else if (titleLower.contains(searchLower)) {
            // Partial match in title
            score += 75.0;
        }
        
        // File type relevance
        if (doc.FileExtension == 'pdf') score += 10.0;
        else if (doc.FileExtension == 'docx') score += 8.0;
        else if (doc.FileExtension == 'xlsx') score += 6.0;
        
        // Recency bonus (newer documents get higher score)
        Long daysSinceModified = Date.today().daysBetween(doc.LastModifiedDate.date());
        if (daysSinceModified <= 7) score += 20.0;
        else if (daysSinceModified <= 30) score += 10.0;
        else if (daysSinceModified <= 90) score += 5.0;
        
        return Math.min(score, 100.0);
    }
    
    private static List<DocumentSearchResult> applyAIRanking(List<DocumentSearchResult> results, String aiQuery) {
        // This would integrate with AI service for semantic search
        // For now, we'll use a simplified approach
        
        for (DocumentSearchResult result : results) {
            // Apply AI-based relevance boost
            result.relevanceScore = result.relevanceScore * 1.1;
            result.aiRanking = calculateAISemanticScore(result.title, aiQuery);
            
            // Combine traditional relevance with AI semantic scoring
            result.combinedScore = (result.relevanceScore * 0.6) + (result.aiRanking * 0.4);
        }
        
        // Sort by combined score (highest first)
        results.sort(new DocumentSearchResultComparator());
        return results;
    }
    
    private static Decimal calculateAISemanticScore(String documentTitle, String aiQuery) {
        // Simplified semantic similarity calculation
        // In production, this would call an external AI service
        
        String titleLower = documentTitle.toLowerCase();
        String queryLower = aiQuery.toLowerCase();
        
        Decimal semanticScore = 0.0;
        
        // Keyword overlap scoring
        List<String> titleWords = titleLower.split(' ');
        List<String> queryWords = queryLower.split(' ');
        
        Integer matchCount = 0;
        for (String queryWord : queryWords) {
            for (String titleWord : titleWords) {
                if (titleWord.contains(queryWord) || queryWord.contains(titleWord)) {
                    matchCount++;
                    break;
                }
            }
        }
        
        if (queryWords.size() > 0) {
            semanticScore = (Decimal.valueOf(matchCount) / queryWords.size()) * 100;
        }
        
        // Apply domain-specific boosts
        if (aiQuery.containsIgnoreCase('personal data') && titleLower.contains('privacy')) {
            semanticScore += 20;
        }
        if (aiQuery.containsIgnoreCase('financial') && titleLower.contains('financial')) {
            semanticScore += 25;
        }
        if (aiQuery.containsIgnoreCase('healthcare') && titleLower.contains('health')) {
            semanticScore += 25;
        }
        
        return Math.min(semanticScore, 100.0);
    }
    
    private static List<String> getAvailableFileTypes() {
        List<String> fileTypes = new List<String>();
        
        // Query existing documents to get available file types
        List<AggregateResult> typeResults = [
            SELECT FileExtension, COUNT(Id) docCount
            FROM ContentDocument
            WHERE FileExtension != null
            GROUP BY FileExtension
            ORDER BY COUNT(Id) DESC
            LIMIT 20
        ];
        
        for (AggregateResult result : typeResults) {
            String fileType = (String) result.get('FileExtension');
            if (String.isNotBlank(fileType)) {
                fileTypes.add(fileType);
            }
        }
        
        return fileTypes;
    }
    
    private static Map<String, Integer> getComplianceStatistics() {
        Map<String, Integer> stats = new Map<String, Integer>();
        
        // Get GDPR compliance statistics
        List<AggregateResult> gdprStats = [
            SELECT GDPR_Compliant__c, COUNT(Id) complianceCount
            FROM DocumentComplianceTracking__c
            WHERE GDPR_Compliant__c != null
            GROUP BY GDPR_Compliant__c
        ];
        
        for (AggregateResult stat : gdprStats) {
            Boolean isCompliant = (Boolean) stat.get('GDPR_Compliant__c');
            Integer count = (Integer) stat.get('complianceCount');
            stats.put('gdpr_' + (isCompliant ? 'compliant' : 'non_compliant'), count);
        }
        
        // Get HIPAA compliance statistics
        List<AggregateResult> hipaaStats = [
            SELECT HIPAA_Compliant__c, COUNT(Id) complianceCount
            FROM DocumentComplianceTracking__c
            WHERE HIPAA_Compliant__c != null
            GROUP BY HIPAA_Compliant__c
        ];
        
        for (AggregateResult stat : hipaaStats) {
            Boolean isCompliant = (Boolean) stat.get('HIPAA_Compliant__c');
            Integer count = (Integer) stat.get('complianceCount');
            stats.put('hipaa_' + (isCompliant ? 'compliant' : 'non_compliant'), count);
        }
        
        return stats;
    }
    
    // Wrapper class for search results
    public class DocumentSearchResult {
        @AuraEnabled public Id documentId { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String fileExtension { get; set; }
        @AuraEnabled public Integer contentSize { get; set; }
        @AuraEnabled public DateTime createdDate { get; set; }
        @AuraEnabled public DateTime lastModifiedDate { get; set; }
        @AuraEnabled public String createdBy { get; set; }
        @AuraEnabled public Decimal complianceScore { get; set; }
        @AuraEnabled public Boolean gdprCompliant { get; set; }
        @AuraEnabled public Boolean hipaaCompliant { get; set; }
        @AuraEnabled public Decimal relevanceScore { get; set; }
        @AuraEnabled public Decimal aiRanking { get; set; }
        @AuraEnabled public Decimal combinedScore { get; set; }
        
        public DocumentSearchResult() {
            this.complianceScore = 0;
            this.gdprCompliant = false;
            this.hipaaCompliant = false;
            this.relevanceScore = 0;
            this.aiRanking = 0;
            this.combinedScore = 0;
        }
    }
    
    // Comparator for sorting search results
    public class DocumentSearchResultComparator implements Comparator<DocumentSearchResult> {
        public Integer compare(DocumentSearchResult a, DocumentSearchResult b) {
            if (a.combinedScore > b.combinedScore) return -1;
            if (a.combinedScore < b.combinedScore) return 1;
            return 0;
        }
    }
}