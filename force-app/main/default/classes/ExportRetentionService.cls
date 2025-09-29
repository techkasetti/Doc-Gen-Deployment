public with sharing class ExportRetentionService {
    @AuraEnabled public static Map<String,Object> evaluateRetention(Integer days) {
        Map<String,Object> out = new Map<String,Object>{'ok'=>true,'candidates'=>0};
        try {
            if (!Schema.getGlobalDescribe().containsKey('Export_File__c')) return out;
            Integer cnt = [SELECT count() FROM Export_File__c WHERE CreatedDate <= :Datetime.now().addDays(-Math.max(1,days))];
            out.put('candidates', cnt);
            return out;
        } catch(Exception ex) { out.put('ok', false); return out; }
    }
}
