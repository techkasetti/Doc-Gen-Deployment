public with sharing class ExportTagCloudController {
    @AuraEnabled public static Map<String,Integer> counts(Integer limitRows) {
        Map<String,Integer> out = new Map<String,Integer>();
        // stub: in prod aggregate Export_Tag__c; return empty map
        return out;
    }
}