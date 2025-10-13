public with sharing class ExportConfigSummaryController {
    @AuraEnabled public static Map<String,Object> getSummary() {
        Map<String,Object> out = new Map<String,Object>{'ok'=>true,'summary'=>new Map<String,Object>()};
        return out;
    }
}
