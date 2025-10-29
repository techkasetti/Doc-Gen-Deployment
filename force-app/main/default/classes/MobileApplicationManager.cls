public with sharing class MobileApplicationManager {
    @AuraEnabled
    public static Boolean registerApp(String name, String owner) {
        if (String.isBlank(name)) return false;
        return true;
    }
}