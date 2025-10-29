public with sharing class TemplateImportService {
    @AuraEnabled
    public static Id importTemplateFromFile(Id contentVersionId) {
        if (contentVersionId == null) return null;
        // stub: create Template__c if present
        if (!Schema.getGlobalDescribe().containsKey('Template__c')) return null;
        try {
            Template__c t = new Template__c(Name='imported-'+String.valueOf(Datetime.now().getTime()));
            insert t;
            return t.Id;
        } catch(Exception ex) {
            return null;
        }
    }
}