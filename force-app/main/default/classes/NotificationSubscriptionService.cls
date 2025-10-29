public with sharing class NotificationSubscriptionService {
    @AuraEnabled
    public static Boolean subscribeUserToNotifications(Id userId, String channel) {
        if (userId == null || String.isBlank(channel)) return false;
        if (!Schema.getGlobalDescribe().containsKey('Notification_Subscription__c')) return true;
        try {
            Notification_Subscription__c s = new Notification_Subscription__c(User__c=userId, Channel__c=channel, SubscribedAt__c=Datetime.now());
            insert s;
            return true;
        } catch(Exception ex) {
            return false;
        }
    }
}