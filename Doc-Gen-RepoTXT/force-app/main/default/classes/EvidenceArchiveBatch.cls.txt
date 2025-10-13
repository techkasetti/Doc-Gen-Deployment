public with sharing class EvidenceArchiveBatch implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        if (!Schema.getGlobalDescribe().containsKey('Evidence_Bundle__c')) {
            return Database.getQueryLocator([SELECT Id FROM Account WHERE Id = :UserInfo.getOrganizationId() LIMIT 1]);
        }
        return Database.getQueryLocator([SELECT Id FROM Evidence_Bundle__c WHERE Archived__c = false AND CreatedAt__c < :Datetime.now().addYears(-1)]);
    }
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            if (scope == null || scope.isEmpty()) return;
            List<Evidence_Bundle__c> rows = (List<Evidence_Bundle__c>)scope;
            for (Evidence_Bundle__c r : rows) r.Archived__c = true;
            update rows;
        } catch(Exception ex) {
            if (Schema.getGlobalDescribe().containsKey('Error_Log__c')) {
                try { insert new Error_Log__c(Message__c='EvidenceArchiveExecErr: '+ex.getMessage()); } catch(Exception e){}
            }
        }
    }
    public void finish(Database.BatchableContext bc) {
        // publish telemetry if available
        if (Schema.getGlobalDescribe().containsKey('Telemetry_Event__c')) {
            try { insert new Telemetry_Event__c(EventName__c='evidence_archive_finished', EventAt__c=Datetime.now()); } catch(Exception e){}
        }
    }
}