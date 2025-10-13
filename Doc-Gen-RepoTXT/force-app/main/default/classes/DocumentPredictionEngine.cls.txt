public with sharing class DocumentPredictionEngine {
    @AuraEnabled
    public static Decimal predictComplexity(Id documentId) {
        try {
            if (documentId == null) return 0.0;
            // placeholder heuristic: length of Name mod factor
            if (!Schema.getGlobalDescribe().containsKey('Document__c')) return 0.0;
            Document__c d = [SELECT Id, Name FROM Document__c WHERE Id = :documentId LIMIT 1];
            Integer len = d.Name == null ? 10 : d.Name.length();
            Decimal score = Math.min(1, (Decimal)len / 100);
            return score;
        } catch(Exception ex) {
            return 0.0;
        }
    }
}
