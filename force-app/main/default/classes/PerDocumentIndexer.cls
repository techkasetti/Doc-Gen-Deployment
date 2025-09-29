public with sharing class PerDocumentIndexer implements Queueable {
    private Id documentId;
    public PerDocumentIndexer(Id documentId){ this.documentId = documentId; }
    public void execute(QueueableContext ctx) {
        if (documentId == null) return;
        // minimal index: write Index_Record__c if exists
        if (!Schema.getGlobalDescribe().containsKey('Index_Record__c')) return;
        Index_Record__c r = new Index_Record__c(Document__c = documentId, IndexedAt__c = Datetime.now());
        insert r;
    }
}