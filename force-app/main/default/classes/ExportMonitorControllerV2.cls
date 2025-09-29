public with sharing class ExportMonitorControllerV2 {
    @AuraEnabled public static Map<String,Integer> summary(Integer days) {
        return new Map<String,Integer>{'exports'=>0,'empty'=>0};
    }
}
