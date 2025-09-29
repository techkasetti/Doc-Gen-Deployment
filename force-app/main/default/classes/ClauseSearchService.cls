public with sharing class ClauseSearchService {
    public static List<Id> searchClauses(String q, Integer limitSize) {
        List<Id> out = new List<Id>();
        if (String.isBlank(q)) return out;
        if (!Schema.getGlobalDescribe().containsKey('Clause__c')) return out;
        List<Clause__c> rows = [SELECT Id FROM Clause__c LIMIT :Math.max(1, limitSize)];
        for (Clause__c c : rows) out.add(c.Id);
        return out;
    }
}