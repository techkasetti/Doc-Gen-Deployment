public with sharing class QuantumOptimizationController {
    @AuraEnabled public static Map<String,Object> optimizeProblem(String problemSpec) {
        if (String.isBlank(problemSpec)) return new Map<String,Object>{'ok'=>false};
        return new Map<String,Object>{'ok'=>true,'solution'=>'placeholder'};
    }
}