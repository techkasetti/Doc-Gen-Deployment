public with sharing class DocumentLifecycleManager {
    @AuraEnabled
    public static Id createLifecycleRecord(String name, String type) {
        try {
            if (!Schema.getGlobalDescribe().containsKey('Job_Run__c')) return null;
            Job_Run__c j = new Job_Run__c(Name = name, Type__c = type, Status__c='CREATED', StartedAt__c=Datetime.now());
            insert j;
            return j.Id;
        } catch (Exception ex) {
            try { if (Schema.getGlobalDescribe().containsKey('Error_Log__c')) insert new Error_Log__c(Message__c='DocumentLifecycleManager:'+ex.getMessage()); } catch(Exception e){}
            return null;
        }
    }
}
