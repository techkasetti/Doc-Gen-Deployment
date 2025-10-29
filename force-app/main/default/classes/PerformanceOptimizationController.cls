public with sharing class PerformanceOptimizationController {
    @AuraEnabled
    public static Boolean applyOptimization(String optimizationKey) {
        if (String.isBlank(optimizationKey)) return false;
        return true;
    }
}