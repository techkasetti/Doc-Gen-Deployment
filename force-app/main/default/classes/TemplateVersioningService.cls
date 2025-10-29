public with sharing class TemplateVersioningService {
    @AuraEnabled public static Id createVersion(Id templateId, String body) {
        try {
            if (templateId == null) return null;
            if (!Schema.getGlobalDescribe().containsKey('Template_Version__c')) return null;
            Template_Version__c v = new Template_Version__c(Template__c = templateId, Body__c = body, CreatedAt__c = Datetime.now());
            insert v;
            return v.Id;
        } catch(Exception ex) { return null; }
    }

    @AuraEnabled public static List<Template_Version__c> listVersions(Id templateId) {
        try {
            if (templateId == null || !Schema.getGlobalDescribe().containsKey('Template_Version__c')) return new List<Template_Version__c>();
            return [SELECT Id, Body__c, CreatedAt__c FROM Template_Version__c WHERE Template__c = :templateId ORDER BY CreatedAt__c DESC LIMIT 50];
        } catch(Exception ex) { return new List<Template_Version__c>(); }
    }
}