public with sharing class DocumentThumbnailService {
    @AuraEnabled
    public static Id generateThumbnail(Id documentId) {
        if (documentId == null) return null;
        try {
            // In production call external renderer; here create Export_File__c as placeholder
            if (!Schema.getGlobalDescribe().containsKey('Export_File__c')) return null;
            Export_File__c ef = new Export_File__c(Name='thumb-'+String.valueOf(Datetime.now().getTime()));
            insert ef;
            return ef.Id;
        } catch(Exception ex) {
            if (Schema.getGlobalDescribe().containsKey('Error_Log__c')) {
                try { insert new Error_Log__c(Message__c='ThumbnailErr:'+ex.getMessage()); } catch(Exception e) {}
            }
            return null;
        }
    }
}