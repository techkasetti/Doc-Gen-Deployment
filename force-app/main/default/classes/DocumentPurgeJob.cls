public with sharing class DocumentPurgeJob implements Schedulable {
    public void execute(SchedulableContext sc) {
        // In prod: purge per retention; here mark Purged__c
        if (!Schema.getGlobalDescribe().containsKey('Document__c')) return;
        List<Document__c> docs = [SELECT Id FROM Document__c WHERE Purged__c = false LIMIT 10];
        for (Document__c d : docs) d.Purged__c = true;
        update docs;
    }
}