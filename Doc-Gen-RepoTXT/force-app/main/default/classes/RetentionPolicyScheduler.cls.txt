public with sharing class RetentionPolicyScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        try {
            // Enqueue retention runner
            System.enqueueJob(new ExportRetentionRunner());
        } catch(Exception ex) {
            try { insert new Error_Log__c(Message__c='RetentionPolicySchedulerErr:'+ex.getMessage()); } catch(Exception e) {}
        }
    }
}
