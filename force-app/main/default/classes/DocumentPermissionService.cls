public with sharing class DocumentPermissionService {
    public static Boolean grantPermission(Id documentId, Id userId, String permission) {
        if (documentId == null || userId == null || String.isBlank(permission)) return false;
        if (!Schema.getGlobalDescribe().containsKey('Document_Permission__c')) return false;
        Document_Permission__c p = new Document_Permission__c(Document__c=documentId, User__c=userId, Permission__c=permission, GrantedAt__c=Datetime.now());
        insert p;
        return true;
    }
}