public with sharing class MicroservicesController {
    @AuraEnabled
    public static Map<String,Object> callService(String serviceName, String path, Map<String,Object> payload) {
        if (String.isBlank(serviceName) || String.isBlank(path)) return new Map<String,Object>{'ok'=>false};
        return new Map<String,Object>{'ok'=>true,'service'=>serviceName,'path'=>path};
    }
}