public with sharing class ComplianceFrameworkController {
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getFramework(String jurisdiction) {
        Map<String,Object> out = new Map<String,Object>{ 'jurisdiction' => jurisdiction, 'framework' => 'general' };
        // TODO: return specific compliance rules metadata
        return out;
    }
}
