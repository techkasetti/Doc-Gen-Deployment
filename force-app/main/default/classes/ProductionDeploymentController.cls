public with sharing class ProductionDeploymentController {
    @AuraEnabled
    public static Map<String,Object> deployToProduction(String packageName) {
        if (String.isBlank(packageName)) return new Map<String,Object>{'ok'=>false};
        return new Map<String,Object>{'ok'=>true,'package'=>packageName,'deployedAt'=>String.valueOf(Datetime.now())};
    }
}
