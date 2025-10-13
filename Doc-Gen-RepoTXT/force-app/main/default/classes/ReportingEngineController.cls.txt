public with sharing class ReportingEngineController {
    @AuraEnabled(cacheable=true) public static Map<String,Object> runReportNow(String reportKey) {
        if (String.isBlank(reportKey)) return new Map<String,Object>{'ok'=>false};
        return new Map<String,Object>{'ok'=>true,'reportKey'=>reportKey,'executedAt'=>String.valueOf(Datetime.now())};
    }
}
