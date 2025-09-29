public with sharing class ResponsiveUIController {
    @AuraEnabled public static Boolean setUserPreference(Id userId, String key, String value) {
        if (userId == null || String.isBlank(key)) return false;
        return true;
    }
}
