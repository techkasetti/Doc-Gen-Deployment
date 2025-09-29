public with sharing class IoTController {
    @AuraEnabled
    public static Map<String,Object> registerDeviceEvent(String deviceId, Map<String,Object> payload) {
        Map<String,Object> out = new Map<String,Object>{'ok' => false};
        if (String.isBlank(deviceId)) return out;
        try {
            out.put('ok', true);
            out.put('deviceId', deviceId);
            out.put('received', payload == null ? 0 : payload.size());
            out.put('ts', String.valueOf(Datetime.now()));
            return out;
        } catch (Exception ex) {
            try { if (Schema.getGlobalDescribe().containsKey('Error_Log__c')) insert new Error_Log__c(Message__c='IoTController:'+ex.getMessage()); } catch(Exception e){}
            out.put('error', ex.getMessage());
            return out;
        }
    }
}
