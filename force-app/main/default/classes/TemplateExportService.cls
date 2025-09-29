public with sharing class TemplateExportService {
    @AuraEnabled
    public static Id exportTemplate(Id templateId) {
        if (templateId == null) return null;
        if (!Schema.getGlobalDescribe().containsKey('Export_File__c')) return null;
        try {
            ContentVersion cv = new ContentVersion(Title='template-'+String.valueOf(templateId), PathOnClient='template.txt', VersionData=Blob.valueOf('template'), IsMajorVersion=true);
            insert cv;
            ContentVersion got = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
            Export_File__c ef = new Export_File__c(Name='template-export-'+String.valueOf(templateId), ContentDocument__c=got.ContentDocumentId, ExportedAt__c=Datetime.now());
            insert ef;
            return ef.Id;
        } catch(Exception ex) {
            return null;
        }
    }
}
