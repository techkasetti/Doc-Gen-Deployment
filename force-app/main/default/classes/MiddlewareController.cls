public with sharing class MiddlewareController {
    @AuraEnabled
    public static Map<String,Object> proxyToMiddleware(String path, Map<String,Object> body) {
        if (String.isBlank(path)) return new Map<String,Object>{'ok'=>false};
        return new Map<String,Object>{'ok'=>true,'path'=>path,'received'=>body == null? 0 : body.size()};
    }
}