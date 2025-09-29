public with sharing class OperatorAuditExporter {
    @AuraEnabled
    public static Id exportOperatorAudits(Integer daysBack) {
        if (!Schema.getGlobalDescribe().containsKey('Export_File__c')) return null;
        try {
            String csv = 'id,ctx,message\n';
            ContentVersion cv = new ContentVersion(Title='ops-audit-'+Date.today(), PathOnClient='ops.csv', VersionData=Blob.valueOf(csv), IsMajorVersion=true);
            insert cv;
            ContentVersion got = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
            Export_File__c ef = new Export_File__c(Name='ops-audit-'+Date.today(), ContentDocument__c=got.ContentDocumentId, ExportedAt__c=Datetime.now());
            insert ef;
            return ef.Id;
        } catch(Exception ex) {
            return null;
        }
    }
}
