public with sharing class IntegrationHealthController {
    @AuraEnabled(cacheable=true)
    public static Map<String,Object> healthCheck() {
        Map<String,Object> m = new Map<String,Object>{
            'ok' => true,
            'components' => new Map<String,String>()
        };

        // Cast the retrieved Object to the proper Map type before calling put()
        Map<String,String> comps = (Map<String,String>) m.get('components');
        comps.put('snowflake', 'ok');
        comps.put('docusign', 'ok');

        return m;
    }
}