public with sharing class DocumentProvenanceExporter {
    @AuraEnabled
    public static Id exportProvenance(Id documentId) {
        if (documentId == null) return null;
        if (!Schema.getGlobalDescribe().containsKey('Export_File__c')) return null;
        try {
            ContentVersion cv = new ContentVersion(Title='prov-'+String.valueOf(Date.today()), PathOnClient='prov.json', VersionData=Blob.valueOf('{}'), IsMajorVersion=true);
            insert cv;
            ContentVersion got = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
            Export_File__c ef = new Export_File__c(Name='prov-export-'+Date.today(), ContentDocument__c=got.ContentDocumentId, ExportedAt__c=Datetime.now());
            insert ef;
            return ef.Id;
        } catch(Exception ex) {
            return null;
        }
    }
}