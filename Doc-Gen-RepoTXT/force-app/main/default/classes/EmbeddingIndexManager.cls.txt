public with sharing class EmbeddingIndexManager {
    public static Boolean flushIndexSnapshot() {
        // In prod: export embeddings to stage/S3 for FAISS loader
        // Here: best-effort record
        if (!Schema.getGlobalDescribe().containsKey('Index_Flush__c')) return false;
        Index_Flush__c f = new Index_Flush__c(FlushedAt__c = Datetime.now());
        insert f;
        return true;
    }
}