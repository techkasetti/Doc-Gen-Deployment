public with sharing class MobileIntegrationManager {
    @AuraEnabled public static Map<String,Object> listMobileIntegrations() {
        try {
            Map<String,Object> out = new Map<String,Object>{'ok'=>true,'integrations'=>new List<Map<String,Object>>()};
            // In production: query Integration records; here return safe stub
            out.get('integrations').add(new Map<String,Object>{'name'=>'push','status'=>'enabled'});
            return out;
        } catch (Exception ex) {
            try { if (Schema.getGlobalDescribe().containsKey('Error_Log__c')) insert new Error_Log__c(Message__c='MobileIntegrationManager:'+ex.getMessage()); } catch(Exception e){}
            return new Map<String,Object>{'ok'=>false,'error'=>ex.getMessage()};
        }
    }
}
