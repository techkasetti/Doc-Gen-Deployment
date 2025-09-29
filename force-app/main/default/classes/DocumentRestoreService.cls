public with sharing class DocumentRestoreService {
    public static Boolean restoreDocument(Id documentId) {
        if (documentId == null) return false;
        if (!Schema.getGlobalDescribe().containsKey('Document__c')) return false;
        Document__c d = [SELECT Id, Purged__c FROM Document__c WHERE Id = :documentId LIMIT 1];
        d.Purged__c = false;
        update d;
        return true;
    }
}