public with sharing class MobileIntegrationController {
    @AuraEnabled
    public static Boolean pushNotificationToken(Id userId, String token) {
        if (userId == null || String.IsBlank(token)) return false;
        return true;
    }
}
