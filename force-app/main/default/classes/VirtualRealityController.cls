public with sharing class VirtualRealityController {
    @AuraEnabled
    public static Map<String,Object> getVRSession(String sessionId) {
        Map<String,Object> out = new Map<String,Object>{ 'sessionId' => sessionId, 'status' => 'inactive' };
        if (String.isBlank(sessionId)) return out;
        // TODO: integrate with VR backend
        out.put('status','active');
        return out;
    }
}