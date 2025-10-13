public with sharing class DocumentMergeService {
    public static Id mergeDocuments(List<Id> inputDocIds, String mergedName) {
        if (inputDocIds == null || inputDocIds.isEmpty()) return null;
        if (!Schema.getGlobalDescribe().containsKey('Document__c')) return null;
        Document__c d = new Document__c(Name = (mergedName==null?'MergedDoc':mergedName));
        insert d;
        return d.Id;
    }
}