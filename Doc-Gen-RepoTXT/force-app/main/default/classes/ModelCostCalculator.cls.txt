public with sharing class ModelCostCalculator {
    @AuraEnabled
    public static Decimal estimateModelCost(String modelKey, Integer tokens) {
        if (String.isBlank(modelKey) || tokens == null) return 0;
        // stub cost calc: $0.0001 per token
        return tokens * 0.0001;
    }
}
