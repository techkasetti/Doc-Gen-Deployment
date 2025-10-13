public with sharing class WebhookManagementController {
    @AuraEnabled public static Map<String,Object> registerWebhook(String name, String url) {
        Map<String,Object> out = new Map<String,Object>{'ok'=>false};
        if (String.isBlank(name) || String.isBlank(url)) return out;
        try {
            // Production: persist webhook record with secret
            out.put('ok', true);
            out.put('name', name);
            out.put('url', url);
            out.put('createdAt', String.valueOf(Datetime.now()));
            return out;
        } catch(Exception ex) {
            out.put('error', ex.getMessage());
            return out;
        }
    }

    @AuraEnabled public static Boolean deleteWebhook(String name) {
        if (String.isBlank(name)) return false;
        // Production: delete record
        return true;
    }
}
