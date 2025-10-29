public class ExportRetentionRunner implements Queueable {
    public void execute(QueueableContext context) {
        try {
            // Call your RetentionService or whatever logic you need
           
        } catch(Exception ex) {
            try { 
                insert new Error_Log__c(Message__c='ExportRetentionRunnerErr: ' + ex.getMessage()); 
            } catch(Exception e) {}
        }
    }
}