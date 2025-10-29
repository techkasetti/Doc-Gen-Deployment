public with sharing class KubernetesController {
    @AuraEnabled
    public static Map<String,Object> deployManifest(String manifestJson) {
        Map<String,Object> out = new Map<String,Object>{'ok' => false};
        if (String.isBlank(manifestJson)) return out;
        try {
            out.put('ok', true);
            out.put('manifestHash', Crypto.generateDigest('SHA256', Blob.valueOf(manifestJson)).toString());
            out.put('deployedAt', String.valueOf(Datetime.now()));
            return out;
        } catch(Exception ex) {
            out.put('error', ex.getMessage());
            return out;
        }
    }
}