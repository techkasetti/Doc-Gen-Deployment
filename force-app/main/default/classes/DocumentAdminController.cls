public with sharing class DocumentAdminController {
    @AuraEnabled public static Map<String,Object> adminHealth() {
        Map<String,Object> out = new Map<String,Object>{'ok'=>true,'details'=>new Map<String,Object>()};
        out.get('details').put('uptime', 'unknown');
        out.get('details').put('indexStatus', 'stale');
        return out;
    }
}