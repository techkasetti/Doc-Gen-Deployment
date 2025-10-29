public with sharing class TemplateSearchController {
    @AuraEnabled(cacheable=true)
    public static List<Template__c> searchTemplates(String q) {
        if (String.isBlank(q) || !Schema.getGlobalDescribe().containsKey('Template__c')) return new List<Template__c>();
        return [SELECT Id, Name FROM Template__c WHERE Name LIKE :('%'+q+'%') LIMIT 50];
    }
}