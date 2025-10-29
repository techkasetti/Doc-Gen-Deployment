public with sharing class CrossPlatformController {
    @AuraEnabled
    public static Map<String,Object> sendNotification(String platform, String deviceId, String message) {
        Map<String,Object> out = new Map<String,Object>{ 'sent' => false };
        if (String.isBlank(platform) || String.isBlank(deviceId)) return out;
        // TODO: call push provider for platform
        out.put('sent', true);
        out.put('sentAt', String.valueOf(Datetime.now()));
        return out;
    }
}