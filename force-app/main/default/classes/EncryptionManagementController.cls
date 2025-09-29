public with sharing class EncryptionManagementController {
    @AuraEnabled
    public static Boolean rotateKey(String keyId) {
        if (String.isBlank(keyId)) return false;
        // stub: rotate key via KMS in prod
        return true;
    }
}
