public class SystemIntegrationManager {
    public class IntegrationResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String integrationId;
        @AuraEnabled public String status;
        @AuraEnabled public Map<String, Object> responseData;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public DateTime processedTime;
    }

    public class WebhookPayload {
        @AuraEnabled public String eventType;
        @AuraEnabled public String sourceSystem;
        @AuraEnabled public Map<String, Object> data;
        @AuraEnabled public String timestamp;
        @AuraEnabled public String signature;
    }

    @AuraEnabled(cacheable=false)
    public static IntegrationResult syncWithExternalSystem(
        String systemName,
        String operation,
        Map<String, Object> payload
    ) {
        IntegrationResult result = new IntegrationResult();
        result.processedTime = DateTime.now();
        result.responseData = new Map<String, Object>();

        try {
            Integration_Configuration__c config = [
                SELECT Id, System_Name__c, Endpoint_URL__c, API_Key__c, Active__c
                FROM Integration_Configuration__c
                WHERE System_Name__c = :systemName
                AND Active__c = true
                LIMIT 1
            ];

            if (config == null) {
                result.success = false;
                result.errorMessage = 'Integration configuration not found for system: ' + systemName;
                return result;
            }

            HttpRequest request = new HttpRequest();
            request.setEndpoint(config.Endpoint_URL__c + '/' + operation);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setHeader('Authorization', 'Bearer ' + config.API_Key__c);
            request.setBody(JSON.serialize(payload));

            Http http = new Http();
            HttpResponse response = http.send(request);

            Integration_Log__c logRecord = new Integration_Log__c(
                Integration_Config__c = config.Id,
                Operation__c = operation,
                Request_Payload__c = JSON.serialize(payload),
                Response_Code__c = response.getStatusCode(),
                Response_Body__c = response.getBody(),
                Timestamp__c = DateTime.now()
            );

            if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
                result.success = true;
                result.status = 'Success';
                logRecord.Status__c = 'Success';

                if (String.isNotBlank(response.getBody())) {
                    result.responseData.putAll(
                        (Map<String, Object>) JSON.deserializeUntyped(response.getBody())
                    );
                }
            } else {
                result.success = false;
                result.errorMessage = 'HTTP ' + response.getStatusCode() + ': ' + response.getStatus();
                logRecord.Status__c = 'Failed';
                logRecord.Error_Message__c = result.errorMessage;
            }

            insert logRecord;
            result.integrationId = logRecord.Id;
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
        }

        return result;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean processIncomingWebhook(String webhookData) {
        try {
            WebhookPayload payload = (WebhookPayload) JSON.deserialize(webhookData, WebhookPayload.class);

            Webhook_Event__c webhookEvent = new Webhook_Event__c(
                Event_Type__c = payload.eventType,
                Source_System__c = payload.sourceSystem,
                Payload__c = webhookData,
                Processed__c = false,
                Received_Date__c = DateTime.now()
            );
            insert webhookEvent;

            switch on payload.eventType {
                when 'DOCUMENT_SIGNED' {
                    return processDocumentSignedWebhook(payload, webhookEvent.Id);
                }
                when 'DOCUMENT_DECLINED' {
                    return processDocumentDeclinedWebhook(payload, webhookEvent.Id);
                }
                when 'COMPLIANCE_ALERT' {
                    return processComplianceAlertWebhook(payload, webhookEvent.Id);
                }
                when else {
                    System.debug('Unknown webhook event type: ' + payload.eventType);
                    return false;
                }
            }
        } catch (Exception e) {
            System.debug('Webhook processing failed: ' + e.getMessage());
            return false;
        }
    }

    private static Boolean processDocumentSignedWebhook(WebhookPayload payload, String webhookEventId) {
        try {
            String documentId = (String) payload.data.get('documentId');
            String signerEmail = (String) payload.data.get('signerEmail');

            if (String.isBlank(documentId) || String.isBlank(signerEmail)) {
                return false;
            }

            List<Signature_Request__c> requests = [
                SELECT Id
                FROM Signature_Request__c
                WHERE Document_Id__c = :documentId
                AND Status__c != 'Completed'
                LIMIT 1
            ];

            if (!requests.isEmpty()) {
                ESignatureIntegration.processSignatureCallback(requests[0].Id, signerEmail, 'SIGNED');
            }

            Webhook_Event__c webhookEvent = [
                SELECT Id FROM Webhook_Event__c WHERE Id = :webhookEventId
            ];
            webhookEvent.Processed__c = true;
            webhookEvent.Processing_Date__c = DateTime.now();
            update webhookEvent;

            return true;
        } catch (Exception e) {
            System.debug('Document signed webhook processing failed: ' + e.getMessage());
            return false;
        }
    }

    private static Boolean processDocumentDeclinedWebhook(WebhookPayload payload, String webhookEventId) {
        try {
            String documentId = (String) payload.data.get('documentId');
            String signerEmail = (String) payload.data.get('signerEmail');

            if (String.isBlank(documentId) || String.isBlank(signerEmail)) {
                return false;
            }

            List<Signature_Request__c> requests = [
                SELECT Id
                FROM Signature_Request__c
                WHERE Document_Id__c = :documentId
                AND Status__c != 'Declined'
                LIMIT 1
            ];

            if (!requests.isEmpty()) {
                ESignatureIntegration.processSignatureCallback(requests[0].Id, signerEmail, 'DECLINED');
            }

            Webhook_Event__c webhookEvent = [
                SELECT Id FROM Webhook_Event__c WHERE Id = :webhookEventId
            ];
            webhookEvent.Processed__c = true;
            webhookEvent.Processing_Date__c = DateTime.now();
            update webhookEvent;

            return true;
        } catch (Exception e) {
            System.debug('Document declined webhook processing failed: ' + e.getMessage());
            return false;
        }
    }

    private static Boolean processComplianceAlertWebhook(WebhookPayload payload, String webhookEventId) {
        try {
            String alertType = (String) payload.data.get('alertType');
            String documentId = (String) payload.data.get('documentId');
            String message = (String) payload.data.get('message');

            Compliance_Alert__c alert = new Compliance_Alert__c(
                Alert_Type__c = alertType,
                Document_Id__c = documentId,
                Message__c = message,
                Severity__c = 'High',
                Status__c = 'Open',
                Created_Date__c = DateTime.now()
            );
            insert alert;

            Webhook_Event__c webhookEvent = [
                SELECT Id FROM Webhook_Event__c WHERE Id = :webhookEventId
            ];
            webhookEvent.Processed__c = true;
            webhookEvent.Processing_Date__c = DateTime.now();
            update webhookEvent;

            return true;
        } catch (Exception e) {
            System.debug('Compliance alert webhook processing failed: ' + e.getMessage());
            return false;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getIntegrationStatus() {
        List<Map<String, Object>> integrations = new List<Map<String, Object>>();

        try {
            List<Integration_Configuration__c> configs = [
                SELECT Id, System_Name__c, Active__c, Last_Sync_Date__c, Health_Status__c
                FROM Integration_Configuration__c
                ORDER BY System_Name__c
            ];

            for (Integration_Configuration__c config : configs) {
                integrations.add(new Map<String, Object>{
                    'id' => config.Id,
                    'systemName' => config.System_Name__c,
                    'active' => config.Active__c,
                    'lastSyncDate' => config.Last_Sync_Date__c,
                    'healthStatus' => config.Health_Status__c
                });
            }
        } catch (Exception e) {
            System.debug('Error retrieving integration status: ' + e.getMessage());
        }

        return integrations;
    }


    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getSignatureRequestHistory(String documentId) {
        List<Map<String, Object>> history = new List<Map<String, Object>>();

        try {
            List<Signature_Request__c> requests = [
                SELECT Id, Status__c, Subject__c, Created_Date__c, Expiration_Date__c,
                    (SELECT Id, Signer_Email__c, Status__c, Signed_Date__c FROM Signature_Participants__r)
                FROM Signature_Request__c
                WHERE Document_Id__c = :documentId
                ORDER BY Created_Date__c DESC
            ];

            for (Signature_Request__c request : requests) {
                Map<String, Object> requestData = new Map<String, Object>();
                requestData.put('id', request.Id);
                requestData.put('status', request.Status__c);
                requestData.put('subject', request.Subject__c);
                requestData.put('createdDate', request.Created_Date__c);
                requestData.put('expirationDate', request.Expiration_Date__c);

                List<Map<String, Object>> participantData = new List<Map<String, Object>>();
                for (Signature_Participant__c participant : request.Signature_Participants__r) {
                    participantData.add(new Map<String, Object>{
                        'email' => participant.Signer_Email__c,
                        'status' => participant.Status__c,
                        'signedDate' => participant.Signed_Date__c
                    });
                }

                requestData.put('participants', participantData);
                history.add(requestData);
            }
        } catch (Exception e) {
            System.debug('Error retrieving signature history: ' + e.getMessage());
        }

        return history;
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getSignatureMetrics() {
        Map<String, Object> metrics = new Map<String, Object>();

        try {
            Date thirtyDaysAgo = Date.today().addDays(-30);
            DateTime thirtyDaysAgoDateTime = DateTime.newInstance(thirtyDaysAgo, Time.newInstance(0, 0, 0, 0));

            Integer totalRequests = [
                SELECT COUNT() FROM Signature_Request__c WHERE CreatedDate >= :thirtyDaysAgoDateTime
            ];
            Integer completedRequests = [
                SELECT COUNT() FROM Signature_Request__c
                WHERE Status__c = 'Completed' AND CreatedDate >= :thirtyDaysAgoDateTime
            ];
            Integer declinedRequests = [
                SELECT COUNT() FROM Signature_Request__c
                WHERE Status__c = 'Declined' AND CreatedDate >= :thirtyDaysAgoDateTime
            ];

            metrics.put('totalRequests', totalRequests);
            metrics.put('completedRequests', completedRequests);
            metrics.put('declinedRequests', declinedRequests);
            metrics.put('pendingRequests', totalRequests - completedRequests - declinedRequests);
            metrics.put('completionRate', totalRequests > 0 ? (completedRequests * 100) / totalRequests : 0);

            List<AggregateResult> avgCompletionTime = [
                SELECT AVG(Days_To_Complete__c) avgDays
                FROM Signature_Request__c
                WHERE Status__c = 'Completed' AND CreatedDate >= :thirtyDaysAgoDateTime
            ];

            if (!avgCompletionTime.isEmpty() && avgCompletionTime[0].get('avgDays') != null) {
                metrics.put('averageCompletionDays', ((Decimal) avgCompletionTime[0].get('avgDays')).setScale(1));
            } else {
                metrics.put('averageCompletionDays', 0);
            }
        } catch (Exception e) {
            metrics.put('error', e.getMessage());
        }

        return metrics;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean sendSignatureReminder(String signatureRequestId, String participantEmail) {
        try {
            Signature_Participant__c participant = [
                SELECT Id, Status__c, Signer_Email__c, Signature_Request__r.Subject__c,
                    Signature_Request__r.Document_Id__r.Document_Name__c
                FROM Signature_Participant__c
                WHERE Signature_Request__c = :signatureRequestId
                AND Signer_Email__c = :participantEmail
                AND Status__c = 'Pending'
                LIMIT 1
            ];

            if (participant == null) {
                return false;
            }

            EmailNotificationService.sendSignatureReminder(participant.Id);

            Audit_Trail__c auditRecord = new Audit_Trail__c(
                Document_Id__c = participant.Signature_Request__r.Document_Id__c,
                Action_Type__c = 'REMINDER_SENT',
                Details__c = 'Signature reminder sent to ' + participantEmail,
                Timestamp__c = DateTime.now()
            );
            insert auditRecord;

            return true;
        } catch (Exception e) {
            System.debug('Failed to send signature reminder: ' + e.getMessage());
            return false;
        }
    }
    // ======================================
    // Reporting & Analytics Methods
    // ======================================

    /**
     * Generate user activity report for given type and date range
     */
    private static Map<String, Object> generateUserActivityReport(
        String reportType,
        Date startDate,
        Date endDate
    ) {
        Map<String, Object> reportData = new Map<String, Object>();

        switch on reportType {
            when 'SIGNATURE_ACTIVITY' {
                // Add signature activity report logic here
                reportData.put('reportType', 'SIGNATURE_ACTIVITY');
                reportData.put('startDate', startDate);
                reportData.put('endDate', endDate);
            }
            when 'COMPLIANCE_ACTIVITY' {
                // Add compliance activity report logic here
                reportData.put('reportType', 'COMPLIANCE_ACTIVITY');
                reportData.put('startDate', startDate);
                reportData.put('endDate', endDate);
            }
            when 'INTEGRATION_ACTIVITY' {
                // Add integration activity report logic here
                reportData.put('reportType', 'INTEGRATION_ACTIVITY');
                reportData.put('startDate', startDate);
                reportData.put('endDate', endDate);
            }
            when else {
                reportData.put('error', 'Invalid report type: ' + reportType);
            }
        }

        return reportData;
    }

    /**
     * Utility: Get date range from string (e.g., "LAST_7_DAYS", "LAST_30_DAYS")
     */
    private static Date getDateFromRange(String range) {
        Date today = Date.today();

        if (range == 'LAST_7_DAYS') {
            return today.addDays(-7);
        } else if (range == 'LAST_30_DAYS') {
            return today.addDays(-30);
        } else if (range == 'LAST_90_DAYS') {
            return today.addDays(-90);
        }

        return today;
    }

    /**
     * Get available report types
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getAvailableReportTypes() {
        return new List<String>{
            'SIGNATURE_ACTIVITY',
            'COMPLIANCE_ACTIVITY',
            'INTEGRATION_ACTIVITY'
        };
    }

    /**
     * Schedule recurring reports
     */
    @AuraEnabled(cacheable=false)
    public static Boolean scheduleRecurringReport(
        String reportType,
        String frequency,
        List<String> recipients
    ) {
        try {
            Date nextRunDate = calculateNextRunDate(frequency);
            // Store schedule record or enqueue job (pseudo code)
            System.debug('Scheduled report: ' + reportType + ' | Frequency: ' + frequency + ' | Next Run: ' + nextRunDate);
            return true;
        } catch (Exception e) {
            System.debug('Failed to schedule recurring report: ' + e.getMessage());
            return false;
        }
    }

    /**
     * Utility: Calculate next run date based on frequency
     */
    private static Date calculateNextRunDate(String frequency) {
        Date today = Date.today();

        if (frequency == 'DAILY') {
            return today.addDays(1);
        } else if (frequency == 'WEEKLY') {
            return today.addDays(7);
        } else if (frequency == 'MONTHLY') {
            return today.addMonths(1);
        }

        return today;
    }

    /**
     * Export report data
     */
    @AuraEnabled(cacheable=false)
    public static String exportReportData(
        String reportType,
        String format,
        Date startDate,
        Date endDate
    ) {
        try {
            Map<String, Object> reportData = generateUserActivityReport(reportType, startDate, endDate);
            // In a real implementation, convert reportData to CSV/Excel/PDF
            return 'Exported ' + reportType + ' report in ' + format + ' format.';
        } catch (Exception e) {
            return 'Export failed: ' + e.getMessage();
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getIntegrationMetrics() {
        Map<String, Object> metrics = new Map<String, Object>();
        try {
            Date thirtyDaysAgo = Date.today().addDays(-30);
            DateTime startDate = DateTime.newInstance(thirtyDaysAgo, Time.newInstance(0, 0, 0, 0));

            // Total integrations in last 30 days
            Integer totalIntegrations = [
                SELECT COUNT() 
                FROM Integration_Log__c 
                WHERE CreatedDate >= :startDate
            ];

            // Success vs Failure distribution
            AggregateResult[] statusDistribution = [
                SELECT Status__c status, COUNT(Id) cnt
                FROM Integration_Log__c
                WHERE CreatedDate >= :startDate
                GROUP BY Status__c
            ];

            // Average processing time
            AggregateResult[] avgTimeResult = [
                SELECT AVG(Processing_Time__c) avgTime
                FROM Integration_Log__c
                WHERE CreatedDate >= :startDate AND Processing_Time__c != null
            ];

            // Populate results
            metrics.put('totalIntegrations', totalIntegrations);
            metrics.put('period', 'Last 30 days');

            Map<String, Integer> statusMap = new Map<String, Integer>();
            for (AggregateResult ar : statusDistribution) {
                String status = (String)ar.get('status');
                Integer count = (Integer)ar.get('cnt');
                statusMap.put(status != null ? status : 'Unknown', count);
            }
            metrics.put('statusDistribution', statusMap);

            if (!avgTimeResult.isEmpty() && avgTimeResult[0].get('avgTime') != null) {
                metrics.put('averageProcessingTime', ((Decimal)avgTimeResult[0].get('avgTime')).setScale(2));
            } else {
                metrics.put('averageProcessingTime', 0);
            }

            // Success rate calculation
            Integer successCount = statusMap.containsKey('Success') ? statusMap.get('Success') : 0;
            Decimal successRate = totalIntegrations > 0 
                ? ((Decimal)successCount / totalIntegrations) * 100 
                : 0;
            metrics.put('successRate', successRate.setScale(2));

        } catch (Exception e) {
            metrics.put('error', e.getMessage());
        }
        return metrics;
    }


}
