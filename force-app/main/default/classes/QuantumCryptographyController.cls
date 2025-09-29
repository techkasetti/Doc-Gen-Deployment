public with sharing class QuantumCryptographyController {
    @AuraEnabled public static Boolean validateQuantumKey(String keyId) {
        if (String.isBlank(keyId)) return false;
        // placeholder - production will call HSM/Quantum service
        return true;
    }
}
