// Advanced Integration Service for External Systems
public class ExternalIntegrationService {
    public class IntegrationRequest {
        @AuraEnabled public String integrationId;
        @AuraEnabled public String systemName;
        @AuraEnabled public String endpoint;
        @AuraEnabled public String method;
        @AuraEnabled public Map<String, String> headers;
        @AuraEnabled public String requestBody;
        @AuraEnabled public Map<String, Object> parameters;
        @AuraEnabled public Integer timeout;
        @AuraEnabled public Boolean retryOnFailure;
    }

    public class IntegrationResponse {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Integer statusCode;
        @AuraEnabled public String responseBody;
        @AuraEnabled public Map<String, String> responseHeaders;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public DateTime responseTime;
        @AuraEnabled public Long executionTimeMs;
    }

    @AuraEnabled(cacheable=false)
    public static IntegrationResponse executeIntegration(IntegrationRequest request) {
        IntegrationResponse response = new IntegrationResponse();
        DateTime startTime = DateTime.now();
        
        try {
            // Create integration log
            Integration_Log__c integrationLog = new Integration_Log__c(
                System_Name__c = request.systemName,
                Endpoint__c = request.endpoint,
                Method__c = request.method,
                Request_Body__c = request.requestBody,
                Status__c = 'In Progress',
                Started_Date__c = startTime
            );
            insert integrationLog;
            
            // Prepare HTTP request
            HttpRequest httpRequest = new HttpRequest();
            httpRequest.setEndpoint(request.endpoint);
            httpRequest.setMethod(request.method != null ? request.method : 'GET');
            
            if (request.timeout != null && request.timeout > 0) {
                httpRequest.setTimeout(request.timeout);
            } else {
                httpRequest.setTimeout(120000); // 2 minutes default
            }
            
            // Set headers
            if (request.headers != null && !request.headers.isEmpty()) {
                for (String headerName : request.headers.keySet()) {
                    httpRequest.setHeader(headerName, request.headers.get(headerName));
                }
            }
            
            // Set request body for POST/PUT requests
            if (String.isNotBlank(request.requestBody)) {
                httpRequest.setBody(request.requestBody);
                if (!request.headers.containsKey('Content-Type')) {
                    httpRequest.setHeader('Content-Type', 'application/json');
                }
            }
            
            // Execute request
            Http http = new Http();
            HttpResponse httpResponse;
            
            try {
                httpResponse = http.send(httpRequest);
                
                response.success = httpResponse.getStatusCode() >= 200 && httpResponse.getStatusCode() < 300;
                response.statusCode = httpResponse.getStatusCode();
                response.responseBody = httpResponse.getBody();
                
                // Extract response headers
                response.responseHeaders = new Map<String, String>();
                // Note: Salesforce doesn't provide direct access to response headers in Apex
                // This would need to be implemented based on specific integration requirements
                
            } catch (CalloutException calloutEx) {
                response.success = false;
                response.errorMessage = 'Callout failed: ' + calloutEx.getMessage();
                response.statusCode = 0;
            }
            
            DateTime endTime = DateTime.now();
            response.responseTime = endTime;
            response.executionTimeMs = endTime.getTime() - startTime.getTime();
            
            // Update integration log
            integrationLog.Status__c = response.success ? 'Success' : 'Failed';
            integrationLog.Response_Body__c = response.responseBody;
            integrationLog.Status_Code__c = response.statusCode;
            integrationLog.Error_Message__c = response.errorMessage;
            integrationLog.Response_Time_Ms__c = response.executionTimeMs;
            integrationLog.Completed_Date__c = endTime;
            update integrationLog;
            
            // Handle retry logic if enabled
            if (!response.success && request.retryOnFailure) {
                response = handleRetry(request, response, integrationLog.Id);
            }
            
        } catch (Exception e) {
            response.success = false;
            response.errorMessage = e.getMessage();
            response.responseTime = DateTime.now();
            response.executionTimeMs = DateTime.now().getTime() - startTime.getTime();
        }
        
        return response;
    }

    private static IntegrationResponse handleRetry(IntegrationRequest originalRequest, IntegrationResponse failedResponse, String originalLogId) {
        try {
            // Wait before retry (simplified - in production, would use queueable or future)
            System.debug('Retrying integration after failure...');
            
            // Create retry log
            Integration_Log__c retryLog = new Integration_Log__c(
                System_Name__c = originalRequest.systemName,
                Endpoint__c = originalRequest.endpoint,
                Method__c = originalRequest.method,
                Request_Body__c = originalRequest.requestBody,
                Status__c = 'Retry',
                Parent_Log_Id__c = originalLogId,
                Started_Date__c = DateTime.now()
            );
            insert retryLog;
            
            // Execute retry (recursive call with retry disabled to prevent infinite loop)
            IntegrationRequest retryRequest = originalRequest;
            retryRequest.retryOnFailure = false;
            
            return executeIntegration(retryRequest);
            
        } catch (Exception e) {
            System.debug('Retry failed: ' + e.getMessage());
            return failedResponse; // Return original failure
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getIntegrationHistory(String systemName, Integer dayLimit) {
        List<Map<String, Object>> history = new List<Map<String, Object>>();
        
        try {
            Integer daysBack = dayLimit != null ? dayLimit : 7;
            DateTime cutoffDate = DateTime.now().addDays(-daysBack);
            
            String query = 'SELECT Id, System_Name__c, Endpoint__c, Method__c, Status__c, ' +
                          'Status_Code__c, Response_Time_Ms__c, Started_Date__c, Completed_Date__c, ' +
                          'Error_Message__c FROM Integration_Log__c WHERE Started_Date__c >= :cutoffDate';
            
            if (String.isNotBlank(systemName)) {
                query += ' AND System_Name__c = :systemName';
            }
            
            query += ' ORDER BY Started_Date__c DESC LIMIT 100';
            
            List<Integration_Log__c> logs = Database.query(query);
            
            for (Integration_Log__c log : logs) {
                history.add(new Map<String, Object>{
                    'id' => log.Id,
                    'systemName' => log.System_Name__c,
                    'endpoint' => log.Endpoint__c,
                    'method' => log.Method__c,
                    'status' => log.Status__c,
                    'statusCode' => log.Status_Code__c,
                    'responseTimeMs' => log.Response_Time_Ms__c,
                    'startedDate' => log.Started_Date__c,
                    'completedDate' => log.Completed_Date__c,
                    'errorMessage' => log.Error_Message__c
                });
            }
            
        } catch (Exception e) {
            System.debug('Error retrieving integration history: ' + e.getMessage());
        }
        
        return history;
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getIntegrationMetrics() {
        Map<String, Object> metrics = new Map<String, Object>();
        
        try {
            DateTime last24Hours = DateTime.now().addHours(-24);
            
            // Success rate
            Integer totalCalls = [SELECT COUNT() FROM Integration_Log__c WHERE Started_Date__c >= :last24Hours];
            Integer successfulCalls = [SELECT COUNT() FROM Integration_Log__c WHERE Status__c = 'Success' AND Started_Date__c >= :last24Hours];
            
            Decimal successRate = totalCalls > 0 ? (successfulCalls * 100.0) / totalCalls : 0;
            
            metrics.put('totalCalls', totalCalls);
            metrics.put('successfulCalls', successfulCalls);
            metrics.put('successRate', successRate.setScale(1));
            
            // Average response time
            List<AggregateResult> avgResponseTime = [
                SELECT AVG(Response_Time_Ms__c) avgTime
                FROM Integration_Log__c 
                WHERE Started_Date__c >= :last24Hours AND Response_Time_Ms__c != null
            ];
            
            if (!avgResponseTime.isEmpty() && avgResponseTime[0].get('avgTime') != null) {
                metrics.put('averageResponseTimeMs', ((Decimal)avgResponseTime[0].get('avgTime')).setScale(0));
            } else {
                metrics.put('averageResponseTimeMs', 0);
            }
            
            // System breakdown
            List<AggregateResult> systemBreakdown = [
                SELECT System_Name__c systemName, COUNT(Id) callCount, 
                       AVG(Response_Time_Ms__c) avgResponseTime
                FROM Integration_Log__c 
                WHERE Started_Date__c >= :last24Hours
                GROUP BY System_Name__c
                ORDER BY COUNT(Id) DESC
            ];
            
            List<Map<String, Object>> systemMetrics = new List<Map<String, Object>>();
            for (AggregateResult ar : systemBreakdown) {
                String systemName = (String)ar.get('systemName');
                Integer callCount = (Integer)ar.get('callCount');
                Decimal avgTime = (Decimal)ar.get('avgResponseTime');
                
                systemMetrics.add(new Map<String, Object>{
                    'systemName' => systemName != null ? systemName : 'Unknown',
                    'callCount' => callCount,
                    'averageResponseTime' => avgTime != null ? avgTime.setScale(0) : 0
                });
            }
            
            metrics.put('systemBreakdown', systemMetrics);
            
            // Error analysis
            List<AggregateResult> errorBreakdown = [
                SELECT Status_Code__c statusCode, COUNT(Id) errorCount
                FROM Integration_Log__c 
                WHERE Started_Date__c >= :last24Hours AND Status__c = 'Failed'
                GROUP BY Status_Code__c
                ORDER BY COUNT(Id) DESC
            ];
            
            List<Map<String, Object>> errorMetrics = new List<Map<String, Object>>();
            for (AggregateResult ar : errorBreakdown) {
                Integer statusCode = (Integer)ar.get('statusCode');
                Integer errorCount = (Integer)ar.get('errorCount');
                errorMetrics.add(new Map<String, Object>{
                    'statusCode' => statusCode != null ? statusCode : 0,
                    'errorCount' => errorCount,
                    'description' => getStatusCodeDescription(statusCode)
                });
            }
            
            metrics.put('errorBreakdown', errorMetrics);
            
        } catch (Exception e) {
            metrics.put('error', e.getMessage());
        }
        
        return metrics;
    }

    private static String getStatusCodeDescription(Integer statusCode) {
        if (statusCode == null) return 'Unknown Error';
        
        switch on statusCode {
            when 400 {
                return 'Bad Request';
            }
            when 401 {
                return 'Unauthorized';
            }
            when 403 {
                return 'Forbidden';
            }
            when 404 {
                return 'Not Found';
            }
            when 500 {
                return 'Internal Server Error';
            }
            when 502 {
                return 'Bad Gateway';
            }
            when 503 {
                return 'Service Unavailable';
            }
            when 504 {
                return 'Gateway Timeout';
            }
            when else {
                return 'HTTP ' + statusCode;
            }
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean testIntegrationConnection(String systemName, String endpoint) {
        try {
            IntegrationRequest testRequest = new IntegrationRequest();
            testRequest.systemName = systemName;
            testRequest.endpoint = endpoint;
            testRequest.method = 'GET';
            testRequest.timeout = 30000; // 30 seconds
            testRequest.retryOnFailure = false;
            
            IntegrationResponse response = executeIntegration(testRequest);
            return response.success;
        } catch (Exception e) {
            System.debug('Integration test failed: ' + e.getMessage());
            return false;
        }
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> createScheduledIntegration(String systemName, String endpoint, String cronExpression, Map<String, Object> parameters) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Create scheduled integration record
            Scheduled_Integration__c scheduledIntegration = new Scheduled_Integration__c(
                System_Name__c = systemName,
                Endpoint__c = endpoint,
                Cron_Expression__c = cronExpression,
                Parameters__c = JSON.serialize(parameters),
                Is_Active__c = true,
                Created_By__c = UserInfo.getUserId(),
                Created_Date__c = DateTime.now()
            );
            insert scheduledIntegration;
            
            // Schedule the job (simplified - would need actual schedulable class)
            System.debug('Scheduled integration created: ' + scheduledIntegration.Id);
            
            result.put('success', true);
            result.put('scheduledIntegrationId', scheduledIntegration.Id);
            result.put('message', 'Integration scheduled successfully');
        } catch (Exception e) {
            result.put('success', false);
            result.put('message', e.getMessage());
        }
        
        return result;
    }

    @AuraEnabled(cacheable=false)
    public static List<Map<String, Object>> getActiveScheduledIntegrations() {
        List<Map<String, Object>> scheduledIntegrations = new List<Map<String, Object>>();
        
        try {
            List<Scheduled_Integration__c> integrations = [
                SELECT Id, System_Name__c, Endpoint__c, Cron_Expression__c,
                       Is_Active__c, Last_Run_Date__c, Next_Run_Date__c,
                       Created_Date__c, CreatedBy.Name
                FROM Scheduled_Integration__c
                WHERE Is_Active__c = true
                ORDER BY Created_Date__c DESC
            ];
            
            for (Scheduled_Integration__c integration : integrations) {
                scheduledIntegrations.add(new Map<String, Object>{
                    'id' => integration.Id,
                    'systemName' => integration.System_Name__c,
                    'endpoint' => integration.Endpoint__c,
                    'cronExpression' => integration.Cron_Expression__c,
                    'isActive' => integration.Is_Active__c,
                    'lastRunDate' => integration.Last_Run_Date__c,
                    'nextRunDate' => integration.Next_Run_Date__c,
                    'createdDate' => integration.Created_Date__c,
                    'createdBy' => integration.CreatedBy.Name
                });
            }
        } catch (Exception e) {
            System.debug('Error retrieving scheduled integrations: ' + e.getMessage());
        }
        
        return scheduledIntegrations;
    }
}