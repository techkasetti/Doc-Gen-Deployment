public with sharing class CloudIntegrationController {
    @AuraEnabled
    public static Map<String,Object> syncStorage(String bucketName) {
        Map<String,Object> out = new Map<String,Object>{ 'bucket' => bucketName, 'status' => 'synced' };
        if (String.isBlank(bucketName)) { out.put('status','error'); out.put('error','missing_bucket'); return out; }
        return out;
    }
}