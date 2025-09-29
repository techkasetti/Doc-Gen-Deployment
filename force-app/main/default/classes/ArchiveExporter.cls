public with sharing class ArchiveExporter {
    public static String exportBundle(Id bundleId) {
        try {
            if (bundleId == null) return null;
            if (!Schema.getGlobalDescribe().containsKey('Evidence_Bundle__c')) return null;
            Evidence_Bundle__c b = [SELECT Id, Item_Count__c FROM Evidence_Bundle__c WHERE Id = :bundleId LIMIT 1];
            // In prod: assemble zip, stage to ContentVersion/S3 etc. Here return pseudo-url
            return '/services/data/vXX.0/sobjects/Evidence_Bundle__c/' + String.valueOf(b.Id) + '/export';
        } catch(Exception ex) {
            return null;
        }
    }
}