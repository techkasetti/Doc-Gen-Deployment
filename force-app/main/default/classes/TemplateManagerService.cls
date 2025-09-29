public with sharing class TemplateManagerService {
    @AuraEnabled public static Id createTemplate(String name, String body, String language) {
        try {
            if (String.isBlank(name)) return null;
            if (!Schema.getGlobalDescribe().containsKey('Template__c')) return null;
            Template__c t = new Template__c(Name = name, Body__c = body, Language__c = language, CreatedAt__c = Datetime.now());
            insert t;
            return t.Id;
        } catch(Exception ex) { return null; }
    }

    @AuraEnabled public static Boolean archiveTemplate(Id templateId) {
        try {
            if (templateId == null) return false;
            if (!Schema.getGlobalDescribe().containsKey('Template__c')) return false;
            Template__c t = new Template__c(Id = templateId, Is_Archived__c = true);
            update t;
            return true;
        } catch(Exception ex) { return false; }
    }
}
