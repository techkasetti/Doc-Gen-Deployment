public with sharing class AdminJobRetryController {
    @AuraEnabled
    public static Boolean retryJob(Id jobRunId) {
        if (jobRunId == null) return false;
        // stub: increment retry counter on Job_Run__c if exists
        return true;
    }
}