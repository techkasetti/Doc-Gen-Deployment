public with sharing class ResponsiveInterfaceManager {
    @AuraEnabled public static Map<String,Object> getInterfaceHints(String page) {
        if (String.isBlank(page)) return new Map<String,Object>{'ok'=>false};
        return new Map<String,Object>{'ok'=>true,'page'=>page,'hints'=>new List<String>()};
    }
}