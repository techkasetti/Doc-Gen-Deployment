public with sharing class MessageQueueController {
    @AuraEnabled
    public static Boolean enqueueMessage(String queueName, Map<String,Object> payload) {
        if (String.isBlank(queueName)) return false;
        try {
            if (Schema.getGlobalDescribe().containsKey('Onboarding_Audit__c')) {
                insert new Onboarding_Audit__c(Context__c='Queue', Message__c='Enqueue '+queueName, CreatedAt__c=Datetime.now());
            }
            return true;
        } catch(Exception ex) {
            return false;
        }
    }
}