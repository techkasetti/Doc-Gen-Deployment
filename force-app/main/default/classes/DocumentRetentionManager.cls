public with sharing class DocumentRetentionManager {
    public static Boolean scheduleRetentionPurge(Integer olderThanDays) {
        // In prod: create Task/Scheduler; here write Retention_Task__c if exists
        if (!Schema.getGlobalDescribe().containsKey('Retention_Task__c')) return false;
        Retention_Task__c t = new Retention_Task__c(TriggerDays__c = olderThanDays, ScheduledAt__c = Datetime.now());
        insert t;
        return true;
    }
}