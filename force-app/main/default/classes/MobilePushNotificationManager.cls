public with sharing class MobilePushNotificationManager {
    @AuraEnabled
    public static Boolean sendPush(String token, String title, String body) {
        if (String.isBlank(token) || String.IsBlank(body)) return false;
        return true;
    }
}