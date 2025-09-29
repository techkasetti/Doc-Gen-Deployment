public with sharing class NaturalLanguageProcessingController {
    @AuraEnabled
    public static Map<String,Object> analyzeText(String text, String model) {
        if (String.isBlank(text)) return new Map<String,Object>{'ok'=>false};
        return new Map<String,Object>{'ok'=>true,'model'=>model,'length'=>text.length()};
    }
}
