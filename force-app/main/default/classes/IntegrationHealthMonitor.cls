public with sharing class IntegrationHealthMonitor implements Schedulable {
    public void execute(SchedulableContext sc) {
        try {
            Map<String,Object> h = IntegrationHealthController.healthCheck();
            if (!((Boolean)h.get('ok'))) {
                // alert ops (stub)
            }
        } catch(Exception ex) {
            try { insert new Error_Log__c(Message__c='IntegrationHealthMonitorErr:'+ex.getMessage()); } catch(Exception e) {}
        }
    }
}
