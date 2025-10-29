public with sharing class EvidenceBundleGenerator {
    @AuraEnabled public static Id generateBundle(Id documentId, List<Id> itemIds) {
        try {
            if (documentId == null) return null;
            if (!Schema.getGlobalDescribe().containsKey('Evidence_Bundle__c')) return null;
            Evidence_Bundle__c b = new Evidence_Bundle__c(Document__c = documentId, Item_Count__c = (Integer)(itemIds==null?0:itemIds.size()), CreatedAt__c = Datetime.now());
            insert b;
            return b.Id;
        } catch(Exception ex) { return null; }
    }
}