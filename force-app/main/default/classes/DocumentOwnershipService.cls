public with sharing class DocumentOwnershipService {
    @AuraEnabled
    public static Boolean transferOwnership(Id documentId, Id newOwnerId) {
        if (documentId == null || newOwnerId == null) return false;
        if (!Schema.getGlobalDescribe().containsKey('Document__c')) return false;
        try {
            Document__c d = new Document__c(Id=documentId, OwnerId=newOwnerId);
            update d;
            return true;
        } catch(Exception ex) {
            return false;
        }
    }
}
