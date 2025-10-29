public with sharing class WebhookRetryService {
    public static Boolean recordRetry(Id integrationCallId, Integer attempt) {
        if (integrationCallId == null || attempt == null) return false;
        if (!Schema.getGlobalDescribe().containsKey('Integration_Call__c')) return false;
        try {
            Integration_Call__c ic = new Integration_Call__c(Id = integrationCallId, Retry_Count__c = attempt);
            update ic;
            return true;
        } catch(Exception ex) {
            return false;
        }
    }
}