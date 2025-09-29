public with sharing class ResourceManagementController {
    @AuraEnabled public static Map<String,Object> listResources() {
        return new Map<String,Object>{'ok'=>true,'resources'=>new List<String>()};
    }
}
