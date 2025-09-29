public with sharing class TemplateVersionManager {
    public static Id createVersion(Id templateId, String contents) {
        if (templateId == null || String.isBlank(contents)) return null;
        if (!Schema.getGlobalDescribe().containsKey('Template_Version__c')) return null;
        Template_Version__c v = new Template_Version__c(Template__c = templateId, Contents__c = contents, CreatedAt__c = Datetime.now());
        insert v;
        return v.Id;
    }
}