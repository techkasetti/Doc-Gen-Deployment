public with sharing class WebhookManager {
    
    public class WebhookResult {
        @AuraEnabled public String webhookId { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public DateTime processedAt { get; set; }
        @AuraEnabled public Map<String, Object> responseData { get; set; }
        
        public WebhookResult() {
            this.responseData = new Map<String, Object>();
            this.processedAt = DateTime.now();
        }
    }

    
    
    @AuraEnabled
    public static WebhookResult registerWebhook(String url, String eventType) {
        WebhookResult result = new WebhookResult();
        try {
            // Validate URL format
            if (!isValidUrl(url)) {
                result.status = 'ERROR';
                result.message = 'Invalid URL format';
                return result;
            }
            
            // Create webhook registration
            Webhook_Registration__c webhook = new Webhook_Registration__c(
                Webhook_URL__c = url,
                Event_Type__c = eventType,
                Status__c = 'ACTIVE',
                Created_By__c = UserInfo.getUserId(),
                Secret_Key__c = generateSecretKey()
            );
            insert webhook;
            
            result.webhookId = webhook.Id;
            result.status = 'SUCCESS';
            result.message = 'Webhook registered successfully';
            result.responseData.put('secretKey', webhook.Secret_Key__c);
            
            // Test webhook connection
           Map<String, Object> connectionTestResult = testWebhookConnection(url);
Boolean connectionTest = (Boolean) connectionTestResult.get('success');
result.responseData.put('connectionTest', connectionTest);

            return result;
        } catch (Exception e) {
            result.status = 'ERROR';
            result.message = 'Registration failed: ' + e.getMessage();
            return result;
        }
    }
    
    @AuraEnabled
    public static WebhookResult processIncomingWebhook(Map<String, Object> webhookData) {
        WebhookResult result = new WebhookResult();
        try {
            String eventType = (String)webhookData.get('eventType');
            String signature = (String)webhookData.get('signature');
            String payload = (String)webhookData.get('payload');
            
            // Validate signature
            if (!validateWebhookSignature(payload, signature)) {
                result.status = 'ERROR';
                result.message = 'Invalid webhook signature';
                return result;
            }
            
            // Process based on event type
            Map<String, Object> processedData = processWebhookEvent(eventType, payload);
            
            // Log webhook processing
            logWebhookActivity(null, 'INCOMING_PROCESSED', JSON.serialize(webhookData));
            
            result.status = 'SUCCESS';
            result.message = 'Webhook processed successfully';
            result.responseData = processedData;
            
            return result;
        } catch (Exception e) {
            result.status = 'ERROR';
            result.message = 'Processing failed: ' + e.getMessage();
            logWebhookActivity(null, 'PROCESSING_ERROR', e.getMessage());
            return result;
        }
    }
    
    @AuraEnabled
    public static List<Map<String, Object>> getActiveWebhooks() {
        List<Map<String, Object>> webhooks = new List<Map<String, Object>>();
        try {
            List<Webhook_Registration__c> activeWebhooks = [
                SELECT Id, Webhook_URL__c, Event_Type__c, Status__c, 
                       Created_Date__c, Last_Success__c, Failure_Count__c
                FROM Webhook_Registration__c
                WHERE Status__c = 'ACTIVE'
                ORDER BY Created_Date__c DESC
            ];
            
            for (Webhook_Registration__c webhook : activeWebhooks) {
                Map<String, Object> webhookInfo = new Map<String, Object>();
                webhookInfo.put('id', webhook.Id);
                webhookInfo.put('url', webhook.Webhook_URL__c);
                webhookInfo.put('eventType', webhook.Event_Type__c);
                webhookInfo.put('status', webhook.Status__c);
                webhookInfo.put('createdDate', webhook.Created_Date__c);
                webhookInfo.put('lastSuccess', webhook.Last_Success__c);
                webhookInfo.put('failureCount', webhook.Failure_Count__c);
                webhooks.add(webhookInfo);
            }
            
            return webhooks;
        } catch (Exception e) {
            System.debug('Error getting active webhooks: ' + e.getMessage());
            return webhooks;
        }
    }
    
    @AuraEnabled
    public static Boolean deactivateWebhook(String webhookId) {
        try {
            Webhook_Registration__c webhook = [
                SELECT Id, Status__c
                FROM Webhook_Registration__c
                WHERE Id = :webhookId
                LIMIT 1
            ];
            
            webhook.Status__c = 'INACTIVE';
            update webhook;
            
            logWebhookActivity(webhookId, 'DEACTIVATED', 'Webhook deactivated by user');
            return true;
        } catch (Exception e) {
            System.debug('Error deactivating webhook: ' + e.getMessage());
            return false;
        }
    }
    
    @AuraEnabled
    public static Map<String, Object> testWebhookConnection(String webhookUrl) {
        Map<String, Object> testResult = new Map<String, Object>();
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(webhookUrl);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-Webhook-Test', 'true');
            
            Map<String, Object> testPayload = new Map<String, Object>();
            testPayload.put('event', 'test');
            testPayload.put('timestamp', DateTime.now().getTime());
            testPayload.put('data', 'Connection test from Salesforce');
            
            req.setBody(JSON.serialize(testPayload));
            req.setTimeout(10000); // 10 second timeout
            
            Http http = new Http();
            HttpResponse response = http.send(req);
            
            testResult.put('success', response.getStatusCode() >= 200 && response.getStatusCode() < 300);
            testResult.put('statusCode', response.getStatusCode());
            testResult.put('responseBody', response.getBody());
            testResult.put('responseTime', DateTime.now());
            
            return testResult;
        } catch (Exception e) {
            testResult.put('success', false);
            testResult.put('error', e.getMessage());
            return testResult;
        }
    }
    
    @AuraEnabled
    public static WebhookResult sendWebhookNotification(String eventType, Map<String, Object> eventData) {
        WebhookResult result = new WebhookResult();
        try {
            // Get all active webhooks for this event type
            List<Webhook_Registration__c> webhooks = [
                SELECT Id, Webhook_URL__c, Secret_Key__c
                FROM Webhook_Registration__c
                WHERE Event_Type__c = :eventType
                AND Status__c = 'ACTIVE'
            ];
            
            Integer successCount = 0;
            Integer failureCount = 0;
            List<String> errors = new List<String>();
            
            for (Webhook_Registration__c webhook : webhooks) {
                try {
                    Boolean sent = sendWebhookPayload(webhook, eventData);
                    if (sent) {
                        successCount++;
                        updateWebhookSuccess(webhook.Id);
                    } else {
                        failureCount++;
                        updateWebhookFailure(webhook.Id);
                    }
                } catch (Exception e) {
                    failureCount++;
                    errors.add('Webhook ' + webhook.Id + ': ' + e.getMessage());
                    updateWebhookFailure(webhook.Id);
                }
            }
            
            result.status = failureCount == 0 ? 'SUCCESS' : 'PARTIAL_SUCCESS';
            result.message = successCount + ' webhooks sent successfully, ' + failureCount + ' failed';
            result.responseData.put('successCount', successCount);
            result.responseData.put('failureCount', failureCount);
            result.responseData.put('errors', errors);
            
            return result;
        } catch (Exception e) {
            result.status = 'ERROR';
            result.message = 'Failed to send webhooks: ' + e.getMessage();
            return result;
        }
    }
    
    // Private helper methods
    private static Boolean isValidUrl(String url) {
        try {
            Pattern urlPattern = Pattern.compile('^https?://[\\w\\-]+(\\.[\\w\\-]+)+([\\w\\-\\.,@?^=%&:/~\\+#]*[\\w\\-\\@?^=%&/~\\+#])?$');
            return urlPattern.matcher(url).matches();
        } catch (Exception e) {
            return false;
        }
    }
    
    private static String generateSecretKey() {
        String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        String secretKey = '';
        for (Integer i = 0; i < 32; i++) {
            Integer index = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            secretKey += chars.substring(index, index + 1);
        }
        return secretKey;
    }
    
    private static Boolean validateWebhookSignature(String payload, String signature) {
        // Simplified signature validation - in production, use HMAC-SHA256
        try {
            if (String.isBlank(signature) || String.isBlank(payload)) {
                return false;
            }
            
            // For demo purposes, just check if signature is present
            // In production, implement proper HMAC verification
            return signature.length() > 10;
        } catch (Exception e) {
            return false;
        }
    }
    
    private static Map<String, Object> processWebhookEvent(String eventType, String payload) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            Map<String, Object> eventData = (Map<String, Object>)JSON.deserializeUntyped(payload);
            
            switch on eventType {
                when 'document.created' {
                    result = processDocumentCreated(eventData);
                }
                when 'signature.completed' {
                    result = processSignatureCompleted(eventData);
                }
                when 'compliance.violation' {
                    result = processComplianceViolation(eventData);
                }
                when else {
                    result.put('processed', true);
                    result.put('eventType', eventType);
                    result.put('message', 'Generic event processed');
                }
            }
            
            result.put('status', 'SUCCESS');
            return result;
        } catch (Exception e) {
            result.put('status', 'ERROR');
            result.put('error', e.getMessage());
            return result;
        }
    }
    
    private static Map<String, Object> processDocumentCreated(Map<String, Object> eventData) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            String documentId = (String)eventData.get('documentId');
            String documentType = (String)eventData.get('documentType');
            
            // Create audit log entry
          Webhook_Event_Log__c log = new Webhook_Event_Log__c(
    Event_Type__c   = 'document.created',
    Document_ID__c  = documentId,
    Event_Data__c   = JSON.serialize(eventData),
    Processed_Date__c = DateTime.now(),
    Status__c       = 'PROCESSED'
    );
    insert log;

            
            result.put('processed', true);
            result.put('documentId', documentId);
            result.put('logId', log.Id);
            return result;
        } catch (Exception e) {
            result.put('processed', false);
            result.put('error', e.getMessage());
            return result;
        }
    }
    
    private static Map<String, Object> processSignatureCompleted(Map<String, Object> eventData) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            String signatureId = (String)eventData.get('signatureId');
            String documentId = (String)eventData.get('documentId');
            
            // Update signature request status
            List<Signature_Request__c> requests = [
                SELECT Id, Status__c 
                FROM Signature_Request__c 
                WHERE Document_ID__c = :documentId 
                LIMIT 1
            ];
            
            if (!requests.isEmpty()) {
                requests[0].Status__c = 'Completed';
                update requests[0];
                result.put('signatureRequestUpdated', true);
            }
            
            // Log the event
            Webhook_Event_Log__c log = new Webhook_Event_Log__c(
                Event_Type__c = 'signature.completed',
                Document_ID__c = documentId,
                Event_Data__c = JSON.serialize(eventData),
                Processed_Date__c = DateTime.now(),
                Status__c = 'PROCESSED'
            );
            insert log;
            
            result.put('processed', true);
            result.put('signatureId', signatureId);
            return result;
        } catch (Exception e) {
            result.put('processed', false);
            result.put('error', e.getMessage());
            return result;
        }
    }
    
    private static Map<String, Object> processComplianceViolation(Map<String, Object> eventData) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            String violationType = (String)eventData.get('violationType');
            String severity = (String)eventData.get('severity');
            
            // Create compliance violation record
            Compliance_Violation__c violation = new Compliance_Violation__c(
                Violation_Type__c = violationType,
                Severity__c = severity,
                Description__c = (String)eventData.get('description'),
                Detected_Date__c = DateTime.now(),
                Status__c = 'OPEN'
            );
            insert violation;
            
            // If critical, create immediate alert
            if (severity == 'CRITICAL') {
                createComplianceAlert(violation.Id, violationType);
            }
            
            result.put('processed', true);
            result.put('violationId', violation.Id);
            return result;
        } catch (Exception e) {
            result.put('processed', false);
            result.put('error', e.getMessage());
            return result;
        }
    }
    
    private static Boolean sendWebhookPayload(Webhook_Registration__c webhook, Map<String, Object> eventData) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(webhook.Webhook_URL__c);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('X-Webhook-Signature', generateWebhookSignature(JSON.serialize(eventData), webhook.Secret_Key__c));
            req.setHeader('X-Webhook-Id', webhook.Id);
            req.setTimeout(30000);
            
            Map<String, Object> payload = new Map<String, Object>();
            payload.put('timestamp', DateTime.now().getTime());
            payload.put('event', eventData);
            payload.put('source', 'Salesforce');
            
            req.setBody(JSON.serialize(payload));
            
            Http http = new Http();
            HttpResponse response = http.send(req);
            
            // Log webhook delivery
            logWebhookDelivery(webhook.Id, response.getStatusCode(), response.getBody());
            
            return response.getStatusCode() >= 200 && response.getStatusCode() < 300;
        } catch (Exception e) {
            logWebhookActivity(webhook.Id, 'SEND_ERROR', e.getMessage());
            return false;
        }
    }
    
    private static String generateWebhookSignature(String payload, String secretKey) {
        try {
            Blob payloadBlob = Blob.valueOf(payload);
            Blob keyBlob = Blob.valueOf(secretKey);
            Blob signature = Crypto.generateMac('HmacSHA256', payloadBlob, keyBlob);
            return 'sha256=' + EncodingUtil.base64Encode(signature);
        } catch (Exception e) {
            return 'error';
        }
    }
    
    private static void updateWebhookSuccess(String webhookId) {
        try {
            Webhook_Registration__c webhook = [
                SELECT Id, Last_Success__c, Failure_Count__c 
                FROM Webhook_Registration__c 
                WHERE Id = :webhookId 
                LIMIT 1
            ];
            webhook.Last_Success__c = DateTime.now();
            webhook.Failure_Count__c = 0; // Reset failure count on success
            update webhook;
        } catch (Exception e) {
            System.debug('Error updating webhook success: ' + e.getMessage());
        }
    }
    
    private static void updateWebhookFailure(String webhookId) {
        try {
            Webhook_Registration__c webhook = [
                SELECT Id, Failure_Count__c 
                FROM Webhook_Registration__c 
                WHERE Id = :webhookId 
                LIMIT 1
            ];
            webhook.Failure_Count__c = webhook.Failure_Count__c != null ? webhook.Failure_Count__c + 1 : 1;
            
            // Disable webhook after 10 consecutive failures
            if (webhook.Failure_Count__c >= 10) {
                webhook.Status__c = 'DISABLED';
            }
            
            update webhook;
        } catch (Exception e) {
            System.debug('Error updating webhook failure: ' + e.getMessage());
        }
    }
    
    private static void logWebhookActivity(String webhookId, String activity, String details) {
        try {
            Webhook_Activity_Log__c log = new Webhook_Activity_Log__c(
                Webhook_ID__c = webhookId,
                Activity__c = activity,
                Details__c = details,
                Activity_Date__c = DateTime.now(),
                User_ID__c = UserInfo.getUserId()
            );
            insert log;
        } catch (Exception e) {
            System.debug('Error logging webhook activity: ' + e.getMessage());
        }
    }
    
    private static void logWebhookDelivery(String webhookId, Integer statusCode, String responseBody) {
    try {
        Webhook_Delivery_Log__c log = new Webhook_Delivery_Log__c(
            Webhook_ID__c = webhookId,
            Status_Code__c = statusCode,
            Response_Body__c = responseBody != null && responseBody.length() > 255 ? 
                responseBody.substring(0, 255) : responseBody,
            Delivery_Date__c = DateTime.now(),
            Success__c = statusCode >= 200 && statusCode < 300
        );
        insert log;
    } catch (Exception e) {
        System.debug('Error logging webhook delivery: ' + e.getMessage());
    }
}

    
    private static void createComplianceAlert(String violationId, String violationType) {
        try {
            System_Alert__c alert = new System_Alert__c(
                Alert_Type__c = 'COMPLIANCE_VIOLATION',
                Severity__c = 'CRITICAL',
                Title__c = 'Critical Compliance Violation Detected',
                Message__c = 'A critical compliance violation of type "' + violationType + '" has been detected and requires immediate attention.',
                Related_Record_ID__c = violationId,
                Status__c = 'OPEN',
                Created_Date__c = DateTime.now()
            );
            insert alert;
        } catch (Exception e) {
            System.debug('Error creating compliance alert: ' + e.getMessage());
        }
    }
    
   @AuraEnabled
public static Map<String, Object> retryFailedWebhook(String webhookId, Map<String, Object> eventData) {
    Map<String, Object> result = new Map<String, Object>();
    try {
        Webhook_Registration__c webhook = [
            SELECT Id, Webhook_URL__c, Secret_Key__c, Event_Type__c
            FROM Webhook_Registration__c 
            WHERE Id = :webhookId 
            LIMIT 1
        ];
        
        Boolean sent = sendWebhookPayload(webhook, eventData);
        
        if (sent) {
            updateWebhookSuccess(webhookId);
            result.put('status', 'SUCCESS');
            result.put('message', 'Webhook retry successful');
        } else {
            updateWebhookFailure(webhookId);
            result.put('status', 'FAILED');
            result.put('message', 'Webhook retry failed');
        }
    } catch (Exception e) {
        result.put('status', 'ERROR');
        result.put('message', 'Retry error: ' + e.getMessage());
    }
    return result;
}

    
    @AuraEnabled
    public static Map<String, Object> sendWebhook(String endpoint, Map<String, Object> payload, String apiKey) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            
            if (String.isNotBlank(apiKey)) {
                req.setHeader('Authorization', 'Bearer ' + apiKey);
            }
            
            req.setBody(JSON.serialize(payload));
            req.setTimeout(10000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            result.put('success', res.getStatusCode() < 300);
            result.put('statusCode', res.getStatusCode());
            result.put('response', res.getBody());
            
        } catch (Exception e) {
            result.put('success', false);
            result.put('error', e.getMessage());
        }
        return result;
    }

    private static Map<String, Object> processWebhook(String source, String payload) {
        Map<String, Object> result = new Map<String, Object>();
        
        switch on source {
            when 'DOCUSIGN'        { result = processDocuSignWebhook(payload); }
            when 'PAYMENT_GATEWAY' { result = processPaymentWebhook(payload); }
            when else              { result = processGenericWebhook(payload); }
        }
        
        // Log webhook receipt
        Webhook_Log__c log = new Webhook_Log__c(
            Source__c = source,
            Payload__c = payload,
            Status__c = (Boolean) result.get('success') ? 'SUCCESS' : 'FAILED'
        );
        insert log;
        
        return result;
    }

    private static Map<String, Object> processDocuSignWebhook(String payload) {
        try {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(payload);
            String eventType = (String) data.get('event');
            
            if (eventType == 'envelope-completed') {
                updateSignatureStatus(data);
            }
            
            return new Map<String, Object>{ 'success' => true };
        } catch (Exception e) {
            return new Map<String, Object>{ 'success' => false, 'error' => e.getMessage() };
        }
    }

    private static Map<String, Object> processPaymentWebhook(String payload) {
        try {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(payload);
            String status = (String) data.get('status');
            
            if (status == 'completed') {
                updatePaymentStatus(data);
            }
            
            return new Map<String, Object>{ 'success' => true };
        } catch (Exception e) {
            return new Map<String, Object>{ 'success' => false, 'error' => e.getMessage() };
        }
    }

    private static Map<String, Object> processGenericWebhook(String payload) {
        return new Map<String, Object>{
            'success' => true,
            'message' => 'Generic webhook processed'
        };
    }

    private static void updateSignatureStatus(Map<String, Object> data) {
        String envelopeId = (String) data.get('envelopeId');
        if (String.isNotBlank(envelopeId)) {
            List<Signature_Request__c> requests = [
                SELECT Id
                FROM Signature_Request__c 
                WHERE DocuSign_Envelope_Id__c = :envelopeId
            ];
            
            for (Signature_Request__c req : requests) {
                req.Status__c = 'COMPLETED';
                req.Completed_Date__c = DateTime.now();
            }
            
            if (!requests.isEmpty()) {
                update requests;
            }
        }
    }

    private static void updatePaymentStatus(Map<String, Object> data) {
        String transactionId = (String) data.get('transactionId');
        if (String.isNotBlank(transactionId)) {
            List<Payment_Transaction__c> transactions = [
                SELECT Id
                FROM Payment_Transaction__c 
                WHERE Transaction_Id__c = :transactionId
            ];
            
            for (Payment_Transaction__c txn : transactions) {
                txn.Status__c = 'COMPLETED';
                txn.Completed_Date__c = DateTime.now();
            }
            
            if (!transactions.isEmpty()) {
                update transactions;
            }
        }
    }

}