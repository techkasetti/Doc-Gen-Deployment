public with sharing class MixedRealityController {
    @AuraEnabled
    public static Map<String,Object> getExperienceConfig(String experienceKey) {
        if (String.isBlank(experienceKey)) return new Map<String,Object>{'ok'=>false};
        return new Map<String,Object>{'ok'=>true,'experience'=>experienceKey};
    }
}
