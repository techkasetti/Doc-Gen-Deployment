public with sharing class PerformanceMonitoringController {
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getRecentMetrics(Integer minutes) {
        if (minutes == null) minutes = 60;
        return new Map<String,Object>{'ok'=>true,'minutes'=>minutes,'metrics'=>new Map<String,Object>()};
    }
}
