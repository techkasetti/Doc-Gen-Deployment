public with sharing class BiometricSecurityManager {
    @AuraEnabled
    public static Map<String,Object> enrollBiometric(String userId, Map<String,Object> payload) {
        Map<String,Object> out = new Map<String,Object>{ 'userId'=>userId, 'enrolled'=>false };
        if (String.isBlank(userId)) return out;
        // TODO: integrate with biometric provider (HSM, FIDO)
        out.put('enrolled', true);
        out.put('enrolledAt', String.valueOf(Datetime.now()));
        return out;
    }
}