public with sharing class LegalHoldService {
    public static Boolean placeLegalHold(Id documentId, String reason) {
        if (documentId == null) return false;
        if (!Schema.getGlobalDescribe().containsKey('Legal_Hold__c')) return false;
        Legal_Hold__c h = new Legal_Hold__c(Document__c = documentId, Reason__c = reason, CreatedAt__c = Datetime.now());
        insert h;
        return true;
    }
}