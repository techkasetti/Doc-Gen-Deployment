public with sharing class APIGatewayController {
    @AuraEnabled
    public static Map<String,Object> proxy(String path, String method, Map<String,Object> body) {
        Map<String,Object> out = new Map<String,Object>{ 'path' => path, 'method' => method, 'status' => 'proxied' };
        // TODO: forward to API gateway via Named Credential
        out.put('proxiedAt', String.valueOf(Datetime.now()));
        return out;
    }
}
