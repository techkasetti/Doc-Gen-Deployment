public with sharing class IntegrationHealthController {
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> healthCheck() {
        Map<String,Object> m = new Map<String,Object>{'ok'=>true,'components'=>new Map<String,String>()};
        m.get('components').put('snowflake','ok');
        m.get('components').put('docusign','ok');
        return m;
    }
}
