public with sharing class ConnectedVehicleController {
    @AuraEnabled
    public static Map<String,Object> getTelematics(String vehicleId) {
        Map<String,Object> out = new Map<String,Object>{ 'vehicleId' => vehicleId, 'connected' => false };
        if (String.isBlank(vehicleId)) return out;
        // TODO: query telematics provider
        out.put('connected', true);
        out.put('lastSeen', String.valueOf(Datetime.now()));
        return out;
    }
}
