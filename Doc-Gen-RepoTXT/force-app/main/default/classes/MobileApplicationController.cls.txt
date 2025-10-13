public with sharing class MobileApplicationController {
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getMobileConfig(String appId) {
        if (String.isBlank(appId)) return new Map<String,Object>{'ok'=>false};
        return new Map<String,Object>{'ok'=>true,'appId'=>appId};
    }
}
