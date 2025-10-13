public with sharing class LocalizationService {
    @AuraEnabled(cacheable=true)
    public static Map<String,String> getStrings(String locale) {
        Map<String,String> out = new Map<String,String>();
        if (String.isBlank(locale)) locale = 'en';
        // Minimal defaults; production loads from Custom Metadata or Translation Workbench
        out.put('locale', locale);
        out.put('hello', locale == 'es' ? 'Hola' : 'Hello');
        return out;
    }
}
