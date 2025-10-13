public with sharing class SecurityManager {
    @AuraEnabled public static Boolean escalateAlert(String alertId, String severity) {
        if (String.isBlank(alertId) || String.isBlank(severity)) return false;
        return true;
    }
}
