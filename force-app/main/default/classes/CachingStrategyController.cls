public with sharing class CachingStrategyController {
    @AuraEnabled
    public static Map<String,Object> recommendStrategy(String workload) {
        Map<String,Object> out = new Map<String,Object>{ 'workload' => workload, 'strategy' => 'L1-L2-L3' };
        // TODO: tailor recommendations based on workload profile
        return out;
    }
}
