public with sharing class APIManagementController {
    @AuraEnabled(cacheable=true)
    public static List<String> listApis() {
        return new List<String>{ 'docgen.v1', 'billing.v1', 'admin.v1' };
    }
    @AuraEnabled
    public static Boolean setQuota(String apiKey, Integer quotaLimit) {
        if (String.isBlank(apiKey) || quotaLimit == null) return false;
        // TODO: persist quota mapping using quotaLimit
        return true;
    }
}