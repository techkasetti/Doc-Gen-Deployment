public with sharing class PredictiveAnalyticsManager {
    @AuraEnabled
    public static Map<String,Object> runPredictionBundle(String bundleKey) {
        if (String.isBlank(bundleKey)) return new Map<String,Object>{'ok'=>false};
        return new Map<String,Object>{'ok'=>true,'bundle'=>bundleKey};
    }
}