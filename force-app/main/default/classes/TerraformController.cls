public with sharing class TerraformController {
    @AuraEnabled public static Boolean applyPlan(String planJson) {
        if (String.isBlank(planJson)) return false;
        return true;
    }
}