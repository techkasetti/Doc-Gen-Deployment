public with sharing class SecurityFrameworkController {
    @AuraEnabled public static Map<String,Object> getSecurityPosture() {
        return new Map<String,Object>{'ok'=>true,'posture'=>'baseline'};
    }
}