public with sharing class TemplatePublishService {
    @AuraEnabled
    public static Boolean publishTemplate(Id templateId) {
        if (templateId == null) return false;
        // stub: mark Template__c as published
        return true;
    }
}
