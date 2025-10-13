public with sharing class ProductionSupportManager {
    @AuraEnabled
    public static Map<String,Object> openIncident(String summary, String severity) {
        if (String.isBlank(summary)) return new Map<String,Object>{'ok'=>false};
        return new Map<String,Object>{'ok'=>true,'incidentId'=>'INC-'+String.valueOf(Datetime.now().getTime())};
    }
}
