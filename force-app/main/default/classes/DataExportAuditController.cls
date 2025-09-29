public with sharing class DataExportAuditController {
    @AuraEnabled
    public static List<Map<String,Object>> listRecentExports(Integer days) {
        List<Map<String,Object>> out = new List<Map<String,Object>>();
        if (days == null) days = 7;
        if (!Schema.getGlobalDescribe().containsKey('Export_File__c')) return out;
        for (Export_File__c e : [SELECT Id, Name, ExportedAt__c FROM Export_File__c WHERE ExportedAt__c >= :Datetime.now().addDays(-days) LIMIT 200]) {
            out.add(new Map<String,Object>{'id'=>e.Id,'name'=>e.Name,'exportedAt'=>String.valueOf(e.ExportedAt__c)});
        }
        return out;
    }
}
