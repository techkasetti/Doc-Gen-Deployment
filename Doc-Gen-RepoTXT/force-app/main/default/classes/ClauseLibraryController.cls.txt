public with sharing class ClauseLibraryController {

    @AuraEnabled
    public static List<Clause__c> getClauses() {
        return [SELECT Id, Name, Clause_Text__c FROM Clause__c LIMIT 50];
    }

    @AuraEnabled
    public static List<Clause__c> searchClauses(String keyword) {
        return [
            SELECT Id, Name, Clause_Text__c 
            FROM Clause__c 
            WHERE Name LIKE :('%' + keyword + '%') 
               OR Clause_Text__c LIKE :('%' + keyword + '%') 
            LIMIT 50
        ];
    }
}
