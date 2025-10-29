public with sharing class DocumentLockService {
    public static Boolean lockDocument(Id documentId, Id userId) {
        if (documentId == null || userId == null) return false;
        // stub: create lock record Document_Lock__c if present
        return true;
    }
}