public with sharing class MetricsCalculator {
    @AuraEnabled
    public static Map<String,Decimal> calculateUsageMetrics(Id tenantId, Integer days) {
        Map<String,Decimal> out = new Map<String,Decimal>();
        out.put('total', 0);
        out.put('average', 0);
        return out;
    }
}
