public with sharing class CrossPlatformConnector {
    @AuraEnabled(cacheable=true)
    public static List<String> supportedPlatforms() {
        return new List<String>{ 'iOS', 'Android', 'Web', 'Electron' };
    }

    @AuraEnabled
    public static Boolean registerDevice(String platform, String deviceId, Map<String,Object> meta) {
        if (String.isBlank(platform) || String.isBlank(deviceId)) return false;
        // TODO: persist device registration
        return true;
    }
}
