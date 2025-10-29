public with sharing class AIModelManager {
    // Typed model config used by UI controllers and Apex callers
    public class AIModelConfig {
        @AuraEnabled public String modelId { get; set; }
        @AuraEnabled public String modelName { get; set; }
        @AuraEnabled public String provider { get; set; }
        @AuraEnabled public String capabilities { get; set; }
        @AuraEnabled public Integer contextWindow { get; set; }

        public AIModelConfig() {}

        public AIModelConfig(String id, String name, String provider, String capabilities, Integer contextWindow) {
            this.modelId = id;
            this.modelName = name;
            this.provider = provider;
            this.capabilities = capabilities;
            this.contextWindow = contextWindow;
        }
    }

    /**
     * Returns a typed list of AIModelConfig.
     * It tries to read AI_Model_Configuration__mdt via dynamic SOQL (so compilation doesn't require the metadata type),
     * and falls back to safe built-in entries if none are found or the query fails at runtime.
     */
    @AuraEnabled(cacheable=true)
    public static List<AIModelConfig> getAvailableAIModels() {
        List<AIModelConfig> out = new List<AIModelConfig>();
        try {
            // Use dynamic SOQL to avoid compile-time dependency on the metadata type existing in every org.
            String mdQuery = 'SELECT DeveloperName, Label, Model_Provider__c, Capabilities__c, Context_Window_Size__c FROM AI_Model_Configuration__mdt WHERE Is_Active__c = true ORDER BY Sort_Order__c NULLS LAST, Label';
            List<SObject> rows = (List<SObject>) Database.query(mdQuery);
            for (SObject s : rows) {
                String devName = (String) s.get('DeveloperName');
                String label = (String) s.get('Label');
                String provider = (String) s.get('Model_Provider__c');
                String caps = (String) s.get('Capabilities__c');
                Integer ctx = 0;
                Object ctxObj = s.get('Context_Window_Size__c');
                if (ctxObj != null) {
                    try { ctx = Integer.valueOf(String.valueOf(ctxObj)); } catch (Exception ex) { ctx = 0; }
                }
                out.add(new AIModelConfig(devName, label, provider, caps, ctx));
            }
        } catch (Exception e) {
            // Dynamic query failure is non-fatal — fall back to built-ins
            System.debug('AIModelManager.getAvailableAIModels: metadata query failed or metadata missing: ' + e.getMessage());
        }

        // Provide safe fallback models if none found
        if (out.isEmpty()) {
            out.add(new AIModelConfig('einstein_gpt_default', 'Einstein GPT (fallback)', 'Salesforce', 'generation,analysis', 4000));
            out.add(new AIModelConfig('external_gpt_fallback', 'External GPT (fallback)', 'External', 'generation', 8000));
        }
        return out;
    }

    // Helper: returns a single typed model config by id (or null)
    @AuraEnabled
    public static AIModelConfig getModelById(String modelId) {
        if (String.isBlank(modelId)) return null;
        for (AIModelConfig c : getAvailableAIModels()) {
            if (c.modelId == modelId) return c;
        }
        return null;
    }

}