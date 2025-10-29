public with sharing class ReportingAutomationController {
    @AuraEnabled public static Map<String,Object> scheduleReport(String reportKey, String cronExpr) {
        if (String.isBlank(reportKey) || String.isBlank(cronExpr)) return new Map<String,Object>{'ok'=>false};
        // production: schedule Apex job; here return stub
        return new Map<String,Object>{'ok'=>true,'reportKey'=>reportKey,'cron'=>cronExpr};
    }
}