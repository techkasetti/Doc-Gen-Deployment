public with sharing class OperatorJobRetryService {
    public static Boolean markRetry(Id jobRunId, Integer increment) {
        if (jobRunId == null) return false;
        // stub: update Job_Run__c Retry_Count__c if present
        return true;
    }
}