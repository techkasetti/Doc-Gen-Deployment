public with sharing class MobileIntegrationManager {
    @AuraEnabled public static Map<String,Object> listMobileIntegrations() {
        // prepare output with a typed empty list
        Map<String,Object> out = new Map<String,Object>{
            'ok' => true,
            'integrations' => new List<Map<String,Object>>()
        };

        try {
            // Cast to the concrete type, then add entries
            List<Map<String,Object>> integrations = (List<Map<String,Object>>) out.get('integrations');
            integrations.add(new Map<String,Object>{
                'name' => 'push',
                'status' => 'enabled'
            });

            // put back (not strictly necessary since we mutated the list, but safe)
            out.put('integrations', integrations);
            return out;
        } catch (Exception ex) {
            // best-effort error logging if the custom object exists
            try {
                if (Schema.getGlobalDescribe().containsKey('Error_Log__c')) {
                    Error_Log__c log = new Error_Log__c(Message__c = 'MobileIntegrationManager:' + ex.getMessage());
                    insert log;
                }
            } catch (Exception ignore) {
                // swallow secondary logging errors
            }
            return new Map<String,Object>{ 'ok' => false, 'error' => ex.getMessage() };
        }
    }
}