public with sharing class DocumentArchivalScheduler {
    public static Boolean scheduleArchival(Integer daysThreshold) {
        if (daysThreshold == null) return false;
        // write task record if object exists
        if (!Schema.getGlobalDescribe().containsKey('Archival_Task__c')) return false;
        Archival_Task__c t = new Archival_Task__c(ThresholdDays__c = daysThreshold, ScheduledAt__c = Datetime.now());
        insert t;
        return true;
    }
}