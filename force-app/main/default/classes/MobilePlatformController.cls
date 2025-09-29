public with sharing class MobilePlatformController {
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> listSupportedPlatforms() {
        Map<String,Object> out = new Map<String,Object>{'ok'=>true,'platforms'=>new List<String>{'ios','android'}};
        return out;
    }
}
