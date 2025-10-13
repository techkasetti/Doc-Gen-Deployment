public with sharing class OperatorJobController {
    @AuraEnabled
    public static List<Job_Run__c> listRecentJobs(Integer days) {
        if (!Schema.getGlobalDescribe().containsKey('Job_Run__c')) return new List<Job_Run__c>();
        try { return [SELECT Id, Name, Status__c, StartedAt__c FROM Job_Run__c WHERE StartedAt__c >= :Datetime.now().addDays(-Math.max(1,days)) ORDER BY StartedAt__c DESC LIMIT 200]; } catch(Exception ex) { return new List<Job_Run__c>(); }
    }
}
