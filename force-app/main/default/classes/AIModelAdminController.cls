public with sharing class AIModelAdminController {
    // Retrieve all AI models from Custom Metadata (existing method retained)
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

    // Existing legacy stub (kept for compatibility) — improved to delegate to testConnection
    @AuraEnabled
    public static String testModelConnection(String modelId) {
        // Default prompt kept for backward compatibility
        return testConnection(modelId, 'Test connection. Respond with: Connection successful.');
    }

    // New enhanced testConnection method that can accept a prompt and performs an HTTP callout (synchronous)
    // Note: Callouts require remote-site or Named Credential configuration in the org and tests must use HttpCalloutMock
    @AuraEnabled
    public static String testConnection(String modelId, String testPrompt) {
        if (String.isBlank(modelId)) {
            return 'ERROR: modelId is required';
        }
        try {
            AI_Model_Configuration__mdt model =
                [ SELECT DeveloperName, Model_Provider__c, API_Endpoint__c, API_Key_Named_Credential__c
                  FROM AI_Model_Configuration__mdt
                  WHERE DeveloperName = :modelId
                  LIMIT 1 ];

            String endpoint = model.API_Endpoint__c;
            String namedCredential = model.API_Key_Named_Credential__c;

            if (String.isBlank(endpoint) && String.isBlank(namedCredential)) {
                return 'ERROR: No API endpoint or Named Credential configured for model ' + model.DeveloperName;
            }

            HttpRequest req = new HttpRequest();
            req.setTimeout(120000);

            // Prefer Named Credential (callout:) if provided — ensures auth is handled securely
            if (!String.isBlank(namedCredential)) {
                // When using a Named Credential, the endpoint should start with "callout:<Name>"
                // The actual path is appended; ensure API_Endpoint__c is a path or empty
                String basePath = endpoint != null ? endpoint : '';
                req.setEndpoint('callout:' + namedCredential + basePath);
            } else {
                // Direct endpoint (requires Remote Site Settings)
                req.setEndpoint(endpoint);
            }

            // Use POST JSON body by default; many model endpoints accept a prompt in body
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');

            Map<String, Object> payload = new Map<String, Object>{
                'prompt' => String.isBlank(testPrompt) ? 'Ping' : testPrompt,
                'modelId' => model.DeveloperName
            };
            req.setBody(JSON.serialize(payload));

            Http http = new Http();
            HttpResponse res = http.send(req);

            Integer status = res.getStatusCode();
            String body = res.getBody();

            if (status >= 200 && status < 300) {
                return 'SUCCESS: ' + body;
            } else {
                return 'ERROR: HTTP ' + status + ' - ' + body;
            }
        } catch (CalloutException coEx) {
            // network / callout error
            return 'ERROR: Callout failed - ' + coEx.getMessage();
        } catch (QueryException qEx) {
            return 'ERROR: Model not found - ' + qEx.getMessage();
        } catch (Exception e) {
            return 'ERROR: ' + e.getMessage();
        }
    }

    // Update runtime status (active/inactive) of a model (existing logic retained, improved error handling)
    @AuraEnabled
    public static void updateModelStatus(String modelId, Boolean isActive) {
        try {
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

    // New: Return consolidated model list for UI consumption (combines metadata + runtime overrides)
    // Returns List<Map<String,Object>> to maximize compatibility with LWC JS
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getModels() {
        List<Map<String, Object>> out = new List<Map<String, Object>>();
        try {
            List<AI_Model_Configuration__mdt> mdts = getAllAIModels();

            // load runtime overrides
            AI_Model_Runtime_Config__c runtime = AI_Model_Runtime_Config__c.getOrgDefaults();
            Map<String, Object> runtimeMap = new Map<String, Object>();
            if (runtime != null && String.isNotBlank(runtime.Active_Models_JSON__c)) {
                runtimeMap = (Map<String, Object>) JSON.deserializeUntyped(runtime.Active_Models_JSON__c);
            }

            for (AI_Model_Configuration__mdt m : mdts) {
                Map<String, Object> row = new Map<String, Object>();
                row.put('id', m.DeveloperName);
                row.put('label', m.Label);
                row.put('provider', m.Model_Provider__c);
                row.put('apiEndpoint', m.API_Endpoint__c);
                row.put('modelType', m.Model_Type__c);
                row.put('contextWindow', m.Context_Window_Size__c);
                row.put('maxTokens', m.Max_Tokens__c);
                row.put('temperature', m.Temperature__c);
                row.put('isActive', m.Is_Active__c);
                row.put('capabilities', m.Capabilities__c);
                row.put('description', m.Description__c);
                row.put('costPerToken', m.Cost_Per_Token__c);

                // apply runtime override if present
                if (runtimeMap.containsKey(m.DeveloperName)) {
                    Object overrideVal = runtimeMap.get(m.DeveloperName);
                    // overrideVal is expected to be Boolean (isActive) or a Map of overrides; handle both
                    if (overrideVal instanceof Boolean) {
                        row.put('isActiveRuntime', (Boolean) overrideVal);
                    } else {
                        row.put('runtimeOverride', overrideVal);
                    }
                }

                out.add(row);
            }
        } catch (Exception e) {
            // return empty list on failure to avoid breaking UI; client should log/notify
        }
        return out;
    }

    // New: Save model runtime metadata (upsert into AI_Model_Runtime_Config__c.Active_Models_JSON__c)
    // modelPayload should include at least 'id' (DeveloperName) and optionally additional runtime keys
    @AuraEnabled
    public static String saveModel(Map<String, Object> modelPayload) {
        if (modelPayload == null || !modelPayload.containsKey('id')) {
            return 'ERROR: Invalid payload - missing id';
        }
        String modelId = String.valueOf(modelPayload.get('id'));
        try {
            AI_Model_Runtime_Config__c runtime = AI_Model_Runtime_Config__c.getOrgDefaults();
            if (runtime == null) {
                runtime = new AI_Model_Runtime_Config__c();
            }

            Map<String, Object> runtimeMap = new Map<String, Object>();
            if (String.isNotBlank(runtime.Active_Models_JSON__c)) {
                runtimeMap = (Map<String, Object>) JSON.deserializeUntyped(runtime.Active_Models_JSON__c);
            }

            // store payload under modelId (keep it as object/map so more than boolean can be stored)
            runtimeMap.put(modelId, modelPayload);
            runtime.Active_Models_JSON__c = JSON.serialize(runtimeMap);
            upsert runtime;
            return 'SUCCESS: model saved';
        } catch (Exception e) {
            return 'ERROR: ' + e.getMessage();
        }
    }

    // New: Delete model runtime override (removes entry from runtime config JSON)
    @AuraEnabled
    public static String deleteModel(String modelId) {
        if (String.isBlank(modelId)) {
            return 'ERROR: modelId required';
        }
        try {
            AI_Model_Runtime_Config__c runtime = AI_Model_Runtime_Config__c.getOrgDefaults();
            if (runtime == null || String.isBlank(runtime.Active_Models_JSON__c)) {
                return 'SUCCESS: no runtime config present';
            }
            Map<String, Object> runtimeMap = (Map<String, Object>) JSON.deserializeUntyped(runtime.Active_Models_JSON__c);
            if (runtimeMap.containsKey(modelId)) {
                runtimeMap.remove(modelId);
                runtime.Active_Models_JSON__c = JSON.serialize(runtimeMap);
                upsert runtime;
            }
            return 'SUCCESS: model runtime override removed';
        } catch (Exception e) {
            return 'ERROR: ' + e.getMessage();
        }
    }
}