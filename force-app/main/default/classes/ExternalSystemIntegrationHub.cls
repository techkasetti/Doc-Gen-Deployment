public with sharing class ExternalSystemIntegrationHub {
    // Public DTO for integration call results
    public class IntegrationResult {
        @AuraEnabled public Boolean success { get; set; }
        @AuraEnabled public Integer statusCode { get; set; }
        @AuraEnabled public String responseBody { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        @AuraEnabled public Long executionTimeMs { get; set; }
        @AuraEnabled public String integrationLogId { get; set; }
        public IntegrationResult() {
            this.success = false;
            this.statusCode = 0;
            this.responseBody = null;
            this.errorMessage = null;
            this.executionTimeMs = 0;
            this.integrationLogId = null;
        }
    }

    // Establish an external connection (safe stub / record creation if config object exists)
    @AuraEnabled
    public static Map<String, Object> establishExternalConnection(String serviceType, Map<String, Object> connectionParams) {
        Map<String, Object> out = new Map<String, Object>{ 'success' => false };
        try {
            out.put('serviceType', serviceType);
            out.put('connectionParams', connectionParams == null ? new Map<String, Object>() : connectionParams);

            // If org contains Integration_Configuration__c, create or update a runtime record (dynamic)
            if (Schema.getGlobalDescribe().containsKey('Integration_Configuration__c')) {
                try {
                    SObject cfg = Schema.getGlobalDescribe().get('Integration_Configuration__c').newSObject();
                    if (connectionParams != null && connectionParams.containsKey('name')) cfg.put('Name', String.valueOf(connectionParams.get('name')));
                    cfg.put('System_Name__c', serviceType);
                    cfg.put('Endpoint_URL__c', connectionParams != null && connectionParams.containsKey('endpoint') ? String.valueOf(connectionParams.get('endpoint')) : null);
                    cfg.put('Active__c', true);
                    insert cfg;
                    out.put('createdConfigId', cfg.get('Id'));
                } catch (Exception e) {
                    // non-fatal: continue and return stub response
                    System.debug('establishExternalConnection: failed to persist Integration_Configuration__c: ' + e.getMessage());
                }
            }

            out.put('success', true);
            out.put('message', 'Connection established (stub).');
        } catch (Exception ex) {
            out.put('error', ex.getMessage());
        }
        return out;
    }

    // Perform an external service call with optional headers; logs activity if Integration_Log__c exists (dynamic)
    @AuraEnabled
public static IntegrationResult performExternalServiceCall(String systemName, String operation, Map<String, Object> requestData) {
    IntegrationResult result = new IntegrationResult();
    Long startTime = DateTime.now().getTime();

    try {
        // --- Guard checks
        if (String.isBlank(systemName) || String.isBlank(operation)) {
            result.errorMessage = 'systemName and operation are required';
            return result;
        }

        // --- Inputs
        String endpoint = null;
        String method = 'POST';
        Map<String, String> headers = new Map<String, String>();
        String body = null;
        Map<String, Object> queryParams = new Map<String, Object>();

        // --- Extract requestData
        if (requestData != null) {
            // endpoint / method
            if (requestData.containsKey('endpoint') && requestData.get('endpoint') != null) {
                endpoint = String.valueOf(requestData.get('endpoint'));
            }
            if (requestData.containsKey('method') && requestData.get('method') != null) {
                method = String.valueOf(requestData.get('method')).toUpperCase();
            }

            // headers: support Map<String,String> or Map<String,Object>
            if (requestData.containsKey('headers') && requestData.get('headers') != null) {
                Object hObj = requestData.get('headers');
                if (hObj instanceof Map<String, String>) {
                    headers = (Map<String, String>)hObj;
                } else if (hObj instanceof Map<String, Object>) {
                    Map<String, Object> hm = (Map<String, Object>)hObj;
                    for (String k : hm.keySet()) headers.put(k, String.valueOf(hm.get(k)));
                }
            }

            // body: String or arbitrary object (serialize)
            if (requestData.containsKey('body') && requestData.get('body') != null) {
                Object b = requestData.get('body');
                body = (b instanceof String) ? String.valueOf(b) : JSON.serialize(b);
            }

            // queryParams: Map<String,Object> (optional)
            if (requestData.containsKey('queryParams') && requestData.get('queryParams') != null) {
                Object qp = requestData.get('queryParams');
                if (qp instanceof Map<String, Object>) {
                    queryParams = (Map<String, Object>)qp;
                }
            }
        }

        // --- Resolve endpoint dynamically if missing (no compile-time dependency)
        if (String.isBlank(endpoint) && Schema.getGlobalDescribe().containsKey('Integration_Configuration__c')) {
            try {
                String sysEsc = String.escapeSingleQuotes(systemName);
                String q = 'SELECT Endpoint_URL__c FROM Integration_Configuration__c ' +
                           'WHERE System_Name__c = \'' + sysEsc + '\' LIMIT 1';
                List<SObject> rows = Database.query(q);
                if (!rows.isEmpty()) {
                    endpoint = String.valueOf(rows[0].get('Endpoint_URL__c'));
                }
            } catch (Exception e) {
                System.debug('performExternalServiceCall: config lookup failed: ' + e.getMessage());
            }
        }

        if (String.isBlank(endpoint)) {
            result.errorMessage = 'No endpoint available for system: ' + systemName;
            return result;
        }

        // --- Append query params if provided
        if (queryParams != null && !queryParams.isEmpty()) {
            List<String> parts = new List<String>();
            for (String k : queryParams.keySet()) {
                String v = (queryParams.get(k) == null) ? '' : String.valueOf(queryParams.get(k));
                parts.add(EncodingUtil.urlEncode(k, 'UTF-8') + '=' + EncodingUtil.urlEncode(v, 'UTF-8'));
            }
            String qs = String.join(parts, '&');
            if (!String.isBlank(qs)) {
                endpoint += (endpoint.contains('?') ? '&' : '?') + qs;
            }
        }

        // --- Build request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setTimeout(120000); // 2 minutes

        // headers
        if (headers != null && !headers.isEmpty()) {
            for (String hk : headers.keySet()) {
                req.setHeader(hk, headers.get(hk));
            }
        }

        // body + default content-type for non-GET methods
        if (!String.isBlank(body) && method != 'GET' && method != 'DELETE') {
            req.setBody(body);
            if (String.isBlank(req.getHeader('Content-Type'))) {
                req.setHeader('Content-Type', 'application/json');
            }
        }

        // --- Execute callout
        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);
        } catch (CalloutException ce) {
            result.errorMessage = 'Callout failed: ' + ce.getMessage();
            return result;
        }

        // --- Populate result
        Long endTime = DateTime.now().getTime();
        result.executionTimeMs = endTime - startTime;
        result.statusCode = res.getStatusCode();
        result.responseBody = res.getBody();
        result.success = res.getStatusCode() >= 200 && res.getStatusCode() < 300;

        // --- Optional logging if Integration_Log__c exists (no compile-time dependency)
        try {
            if (Schema.getGlobalDescribe().containsKey('Integration_Log__c')) {
                SObject logRec = Schema.getGlobalDescribe().get('Integration_Log__c').newSObject();
                logRec.put('System_Name__c', systemName);
                logRec.put('Operation__c', operation);
                logRec.put('Endpoint__c', endpoint);
                logRec.put('Request_Payload__c', body);
                logRec.put('Status__c', result.success ? 'Success' : 'Failed');
                logRec.put('Status_Code__c', result.statusCode);
                logRec.put('Response_Payload__c', result.responseBody);
                logRec.put('Execution_Time_Ms__c', result.executionTimeMs);
                insert logRec;
                result.integrationLogId = String.valueOf(logRec.get('Id'));
            }
        } catch (Exception e) {
            System.debug('performExternalServiceCall: failed to persist Integration_Log__c: ' + e.getMessage());
        }

        return result;
    } catch (Exception ex) {
        result.errorMessage = ex.getMessage();
        return result;
    }
}


    // Return integration status records (dynamic), or stub if not present
    @AuraEnabled
    public static List<Map<String, Object>> getIntegrationStatus(String systemName) {
        List<Map<String, Object>> out = new List<Map<String, Object>>();
        try {
            if (Schema.getGlobalDescribe().containsKey('Integration_Configuration__c')) {
                try {
                    String q = 'SELECT Id, System_Name__c, Endpoint_URL__c, Active__c FROM Integration_Configuration__c';
                    if (!String.isBlank(systemName)) q += ' WHERE System_Name__c = :systemName';
                    List<SObject> rows = Database.query(q);
                    for (SObject r : rows) {
                        Map<String, Object> m = new Map<String, Object>();
                        m.put('id', r.get('Id'));
                        m.put('systemName', r.get('System_Name__c'));
                        m.put('endpoint', r.get('Endpoint_URL__c'));
                        m.put('active', r.get('Active__c') == true);
                        out.add(m);
                    }
                    return out;
                } catch (Exception e) {
                    System.debug('getIntegrationStatus: dynamic query failed: ' + e.getMessage());
                }
            }

            // Fallback stub
            out.add(new Map<String, Object>{ 'systemName' => systemName != null ? systemName : 'stub', 'endpoint' => '/api/stub', 'active' => true });
            return out;
        } catch (Exception ex) {
            System.debug('getIntegrationStatus error: ' + ex.getMessage());
            return out;
        }
    }

    // Helper: send webhook-style payloads for integrations that expect simple delivery
    @AuraEnabled
    public static IntegrationResult sendWebhookPayload(String webhookUrl, Map<String, Object> payload) {
        IntegrationResult res = new IntegrationResult();
        try {
            if (String.isBlank(webhookUrl)) {
                res.errorMessage = 'webhookUrl required';
                return res;
            }
            HttpRequest req = new HttpRequest();
            req.setEndpoint(webhookUrl);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(payload));
            req.setTimeout(60000);
            Http http = new Http();
            HttpResponse resp = http.send(req);
            res.statusCode = resp.getStatusCode();
            res.responseBody = resp.getBody();
            res.success = resp.getStatusCode() >= 200 && resp.getStatusCode() < 300;
            return res;
        } catch (Exception e) {
            res.errorMessage = e.getMessage();
            return res;
        }
    }

    // Small utility: safe JSON serialize helper
    private static String safeSerialize(Object o) {
        try { return JSON.serialize(o); } catch (Exception e) { return String.valueOf(o); }
    }
}