public with sharing class ExportDiscoveryController {
    @AuraEnabled public static List<Map<String,Object>> discoverRecent(Integer days) {
        List<Map<String,Object>> out = new List<Map<String,Object>>();
        if (!Schema.getGlobalDescribe().containsKey('Export_File__c')) return out;
        for (Export_File__c f : [SELECT Id, Name, CreatedDate FROM Export_File__c WHERE CreatedDate >= :Datetime.now().addDays(-Math.max(1,days)) LIMIT 200]) {
            out.add(new Map<String,Object>{'id'=>f.Id,'name'=>f.Name,'created'=>String.valueOf(f.CreatedDate)});
        }
        return out;
    }
}