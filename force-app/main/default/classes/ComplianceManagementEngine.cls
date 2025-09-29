public with sharing class ComplianceManagementEngine {
    @AuraEnabled
    public static Map<String,Object> evaluate(String jurisdiction, String documentId) {
        Map<String,Object> out = new Map<String,Object>{ 'jurisdiction' => jurisdiction, 'documentId' => documentId, 'compliant' => true };
        // TODO: run detailed checks vs rules
        out.put('evaluatedAt', String.valueOf(Datetime.now()));
        return out;
    }
}
