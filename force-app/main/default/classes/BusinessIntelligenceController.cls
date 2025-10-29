public with sharing class BusinessIntelligenceController {
    @AuraEnabled
    public static Map<String,Object> exportReport(String reportId) {
        Map<String,Object> out = new Map<String,Object>{ 'reportId' => reportId, 'status' => 'exported' };
        if (String.isBlank(reportId)) { out.put('status','error'); out.put('error','missing_reportId'); return out; }
        out.put('exportedAt', String.valueOf(Datetime.now()));
        return out;
    }
}