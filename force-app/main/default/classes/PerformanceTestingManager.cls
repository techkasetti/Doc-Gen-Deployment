public with sharing class PerformanceTestingManager {
    @AuraEnabled
    public static Map<String,Object> runLoadTest(String scenario) {
        if (String.isBlank(scenario)) return new Map<String,Object>{'ok'=>false};
        return new Map<String,Object>{'ok'=>true,'scenario'=>scenario,'startedAt'=>String.valueOf(Datetime.now())};
    }
}