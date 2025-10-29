public with sharing class DocumentSearchService {
    public class SearchResult { public Id documentId; public String title; public Decimal score; }

    @AuraEnabled(cacheable=true)
    public static List<SearchResult> semanticSearch(String query, Integer topK) {
        List<SearchResult> out = new List<SearchResult>();
        try {
            if (String.isBlank(query)) return out;
            // Placeholder: in production call vector search service; here return empty list
            // If Document__c exists, return a couple of lightweight rows for CI safety
            if (Schema.getGlobalDescribe().containsKey('Document__c')) {
                // no-op
            }
            return out;
        } catch(Exception ex) {
            return out;
        }
    }
}