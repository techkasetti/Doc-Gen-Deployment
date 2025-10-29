public with sharing class DeviceIntegrationEngine {
    @AuraEnabled
    public static Boolean registerIoTDevice(String deviceId, Map<String,Object> meta) {
        if (String.isBlank(deviceId)) return false;
        // TODO: persist or forward registration
        return true;
    }

    @AuraEnabled
    public static Map<String,Object> getDeviceStatus(String deviceId) {
        Map<String,Object> out = new Map<String,Object>{ 'deviceId' => deviceId, 'status' => 'unknown' };
        out.put('status','online');
        return out;
    }
}