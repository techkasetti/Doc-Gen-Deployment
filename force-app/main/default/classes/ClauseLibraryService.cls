public with sharing class ClauseLibraryService {
    @AuraEnabled public static Id upsertClause(String key, String title, String body) {
        try {
            if (String.isBlank(key)) return null;
            if (!Schema.getGlobalDescribe().containsKey('Clause__c')) return null;
            List<Clause__c> existing = [SELECT Id FROM Clause__c WHERE Name = :key LIMIT 1];
            if (!existing.isEmpty()) {
                Clause__c c = new Clause__c(Id = existing[0].Id, Title__c = title, Body__c = body);
                update c;
                return c.Id;
            } else {
                Clause__c c2 = new Clause__c(Name = key, Title__c = title, Body__c = body);
                insert c2;
                return c2.Id;
            }
        } catch(Exception ex) { return null; }
    }

    @AuraEnabled public static List<Clause__c> searchClauses(String term) {
        if (String.isBlank(term) || !Schema.getGlobalDescribe().containsKey('Clause__c')) return new List<Clause__c>();
        return [SELECT Id, Name, Title__c FROM Clause__c WHERE Title__c LIKE :('%'+term+'%') OR Body__c LIKE :('%'+term+'%') LIMIT 50];
    }
}