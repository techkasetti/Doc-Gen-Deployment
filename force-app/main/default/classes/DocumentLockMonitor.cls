public with sharing class DocumentLockMonitor implements Schedulable {
    public void execute(SchedulableContext sc) {
        try {
            // find stale locks and remove (stub)
        } catch(Exception ex) {
            try { insert new Error_Log__c(Message__c='DocLockMonitorErr:'+ex.getMessage()); } catch(Exception e) {}
        }
    }
}