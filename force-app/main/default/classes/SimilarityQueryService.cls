public with sharing class SimilarityQueryService {
    public static List<Id> findSimilarDocuments(List<Double> vector, Integer topK) {
        // local fallback: query Document_Embedding__c for simple equality-based heuristic
        List<Id> out = new List<Id>();
        if (vector == null || topK == null) return out;
        if (!Schema.getGlobalDescribe().containsKey('Document_Embedding__c')) return out;
        List<Document_Embedding__c> rows = [SELECT Document__c FROM Document_Embedding__c LIMIT :topK];
        for (Document_Embedding__c r : rows) out.add(r.Document__c);
        return out;
    }
}