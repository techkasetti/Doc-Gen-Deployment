public with sharing class DocumentCollaborationEngine {
    @AuraEnabled
    public static Id createThread(Id documentId, String subject, String body) {
        try {
            if (documentId == null || String.isBlank(subject)) return null;
            if (!Schema.getGlobalDescribe().containsKey('Collaboration_Thread__c')) return null;
            Collaboration_Thread__c t = new Collaboration_Thread__c(Document__c = documentId, Subject__c = subject, Body__c = body, CreatedAt__c = Datetime.now());
            insert t;
            return t.Id;
        } catch(Exception ex) {
            // best effort log
            return null;
        }
    }
}
