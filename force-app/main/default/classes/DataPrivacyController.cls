public with sharing class DataPrivacyController {
    @AuraEnabled
    public static Boolean requestErasure(String subjectId) {
        if (String.isBlank(subjectId)) return false;
        // TODO: trigger erasure workflow, write audit
        return true;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String,Object> getPrivacyStatus(String subjectId) {
        Map<String,Object> out = new Map<String,Object>{ 'subjectId' => subjectId, 'status' => 'none' };
        if (!String.isBlank(subjectId)) out.put('status','active');
        return out;
    }
}