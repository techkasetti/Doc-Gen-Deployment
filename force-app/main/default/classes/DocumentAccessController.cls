public with sharing class DocumentAccessController {
    @AuraEnabled public static Boolean grantAccess(Id documentId, Id userId, String level) {
        try {
            if (documentId == null || userId == null) return false;
            // Best-effort: write an access record if object exists
            if (Schema.getGlobalDescribe().containsKey('Document_Access__c')) {
                Document_Access__c a = new Document_Access__c(Document__c = documentId, User__c = userId, Access_Level__c = level, GrantedAt__c = Datetime.now());
                insert a;
            }
            return true;
        } catch(Exception ex) {
            return false;
        }
    }
}