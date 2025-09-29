public with sharing class WebhookProcessingEngine {
    @AuraEnabled public static Boolean processIncoming(String signature, String body) {
        if (String.isBlank(body)) return false;
        try {
            // Verify signature in production; here accept if body present
            if (Schema.getGlobalDescribe().containsKey('Integration_Call__c')) {
                insert new Integration_Call__c(Integration_Name__c='Webhook', Request_Body__c=body, Called_At__c=Datetime.now(), Status_Code__c=200);
            }
            return true;
        } catch (Exception ex) {
            try { if (Schema.getGlobalDescribe().containsKey('Error_Log__c')) insert new Error_Log__c(Message__c='WebhookProcessingEngine:'+ex.getMessage()); } catch(Exception e){}
            return false;
        }
    }
}
