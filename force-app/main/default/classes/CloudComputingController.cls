public with sharing class CloudComputingController {
    @AuraEnabled
    public static Map<String,Object> provisionInstance(String flavor, Integer count) {
        Map<String,Object> out = new Map<String,Object>{ 'flavor' => flavor, 'count' => count, 'status' => 'requested' };
        // TODO: call cloud infra provisioning API
        out.put('requestedAt', String.valueOf(Datetime.now()));
        out.put('status','provisioned');
        return out;
    }
}