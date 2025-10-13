public with sharing class QuantumComputingController {
    @AuraEnabled public static Map<String,Object> getQuantumStatus() {
        return new Map<String,Object>{'ok'=>true,'available'=>false,'notes'=>'placeholder - no quantum backend'};
    }
}
