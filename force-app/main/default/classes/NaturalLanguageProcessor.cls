public with sharing class NaturalLanguageProcessor {
    @AuraEnabled
    public static Map<String,Object> process(String input) {
        if (String.isBlank(input)) return new Map<String,Object>{'ok'=>false};
        return new Map<String,Object>{'ok'=>true,'tokens'=>input.split('\\s').size()};
    }
}