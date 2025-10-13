public with sharing class EmbeddingIngestWorker implements Queueable {
    private Id docId;
    private List<Double> vector;
    public EmbeddingIngestWorker(Id docId, List<Double> vector){ this.docId = docId; this.vector = vector; }
    public void execute(QueueableContext ctx) {
        if (docId == null || vector == null) return;
        if (!Schema.getGlobalDescribe().containsKey('Document_Embedding__c')) return;
        Document_Embedding__c e = new Document_Embedding__c(Document__c = docId, Embedding_JSON__c = JSON.serialize(vector), CreatedAt__c = Datetime.now());
        insert e;
    }
}