public with sharing class MicroservicesArchitectureManager {
    @AuraEnabled
    public static Map<String,Object> getTopology() {
        Map<String,Object> out = new Map<String,Object>{'ok'=>true,'services'=>new List<String>()};
        return out;
    }
}
