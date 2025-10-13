public with sharing class ProgressiveWebAppController {
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getPwaConfig(String tenantId) {
        Map<String,Object> out = new Map<String,Object>{'ok'=>false};
        if (String.isBlank(tenantId)) return out;
        try {
            out.put('ok', true);
            out.put('tenantId', tenantId);
            out.put('manifestVersion', '1.0');
            out.put('offlineReady', false);
            return out;
        } catch (Exception ex) {
            try { if (Schema.getGlobalDescribe().containsKey('Error_Log__c')) insert new Error_Log__c(Message__c = 'ProgressiveWebAppController:'+ex.getMessage()); } catch(Exception e){}
            out.put('error', ex.getMessage());
            return out;
        }
    }
}
