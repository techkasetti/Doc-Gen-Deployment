public with sharing class ContextAwareQueueableAnalyzer implements Queueable {
    private String payloadId;
    public ContextAwareQueueableAnalyzer(String payloadId) {
        this.payloadId = payloadId;
    }

    public void execute(QueueableContext qc) {
        try {
            // Placeholder processing. Replace with actual analysis invocation.
            System.debug('Processing payloadId=' + payloadId);
            // Example: write a lightweight audit record if object exists (guarded).
            if (Schema.getGlobalDescribe().containsKey('Onboarding_Audit__c')) {
                Onboarding_Audit__c a = new Onboarding_Audit__c(Context__c='ContextAwareQueueableAnalyzer', Message__c='Processed '+payloadId, CreatedAt__c=Datetime.now());
                insert a;
            }
        } catch (Exception ex) {
            System.debug('ContextAwareQueueableAnalyzer failed: ' + ex.getMessage());
        }
    }

    public static Id enqueue(String payloadId) {
        return System.enqueueJob(new ContextAwareQueueableAnalyzer(payloadId));
    }
}
