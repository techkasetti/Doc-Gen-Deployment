public with sharing class EvidenceArchiveService {
    @AuraEnabled public static Boolean archiveBundle(Id bundleId) {
        try {
            if (bundleId == null) return false;
            if (!Schema.getGlobalDescribe().containsKey('Evidence_Bundle__c')) return false;
            Evidence_Bundle__c b = new Evidence_Bundle__c(Id = bundleId, Archived__c = true);
            update b;
            return true;
        } catch(Exception ex) { return false; }
    }
}