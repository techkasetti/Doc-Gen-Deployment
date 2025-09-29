public with sharing class IndexingWorker implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (!Schema.getGlobalDescribe().containsKey('Document__c')) {
            return Database.getQueryLocator([SELECT Id FROM Account WHERE Id = :UserInfo.getOrganizationId() LIMIT 1]);
        }
        return Database.getQueryLocator([SELECT Id FROM Document__c WHERE Needs_Index__c = true]);
    }
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<PerDocumentIndexer> jobs = new List<PerDocumentIndexer>();
        for (SObject s : scope) {
            Document__c d = (Document__c)s;
            System.enqueueJob(new PerDocumentIndexer(d.Id));
        }
    }
    public void finish(Database.BatchableContext bc){}
}