// Phase 7: Admin Configuration for AI Models
public with sharing class AIModelAdminController {

    // Retrieve all AI models from Custom Metadata
    @AuraEnabled(cacheable=true)
    public static List<AI_Model_Configuration__mdt> getAllAIModels() {
        return [
            SELECT Id, Label, DeveloperName, Model_Provider__c, API_Endpoint__c, 
                   Model_Type__c, Context_Window_Size__c, Max_Tokens__c, 
                   Temperature__c, Is_Active__c, Capabilities__c, Sort_Order__c,
                   Description__c, Cost_Per_Token__c
            FROM AI_Model_Configuration__mdt
            ORDER BY Sort_Order__c, Label
        ];
    }

    // Test connection to a specific AI model
    @AuraEnabled
    public static String testModelConnection(String modelId) {
        try {
            AI_Model_Configuration__mdt model = [
                SELECT DeveloperName, Model_Provider__c, API_Endpoint__c
                FROM AI_Model_Configuration__mdt
                WHERE DeveloperName = :modelId
                LIMIT 1
            ];

            // Test connection with a simple prompt
            String testPrompt = 'Test connection. Respond with: Connection successful.';
            String response = AIModelManager.processWithEinstein(modelId, testPrompt, '');

            return 'SUCCESS: ' + response;
        } catch (Exception e) {
            return 'ERROR: ' + e.getMessage();
        }
    }

    // Update runtime status (active/inactive) of a model
    @AuraEnabled
    public static void updateModelStatus(String modelId, Boolean isActive) {
        try {
            // Custom Metadata is read-only; use a runtime config object
            AI_Model_Runtime_Config__c config = AI_Model_Runtime_Config__c.getOrgDefaults();
            if (config == null) {
                config = new AI_Model_Runtime_Config__c();
            }

            Map<String, Object> activeModels = new Map<String, Object>();
            if (String.isNotBlank(config.Active_Models_JSON__c)) {
                activeModels = (Map<String, Object>) JSON.deserializeUntyped(config.Active_Models_JSON__c);
            }

            activeModels.put(modelId, isActive);
            config.Active_Models_JSON__c = JSON.serialize(activeModels);

            upsert config;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to update model status: ' + e.getMessage());
        }
    }
}
