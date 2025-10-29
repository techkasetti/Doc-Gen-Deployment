/**
 * @description Essential API Gateway Manager - Core API operations only
 */
public with sharing class APIGatewayManager {

    // ================== API Registration ==================
    @AuraEnabled
    public static Map<String, Object> registerAPI(String apiName, String endpoint, String method, String description) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            API_Registration__c apiReg = new API_Registration__c(
                Name = apiName,
                Endpoint__c = endpoint,
                HTTP_Method__c = method,
                Description__c = description,
                Status__c = 'ACTIVE',
                Created_By__c = UserInfo.getUserId(),
                Created_Date__c = DateTime.now()
            );
            insert apiReg;

            result.put('success', true);
            result.put('apiId', apiReg.Id);
            result.put('message', 'API registered successfully');
        } catch (Exception e) {
            result.put('success', false);
            result.put('error', e.getMessage());
        }
        return result;
    }

    // ================== API Call ==================
    @AuraEnabled
    public static Map<String, Object> makeAPICall(String apiId, Map<String, Object> parameters, Map<String, String> headers) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            API_Registration__c apiReg = [
                SELECT Id, Endpoint__c, HTTP_Method__c, Status__c
                FROM API_Registration__c
                WHERE Id = :apiId AND Status__c = 'ACTIVE'
                LIMIT 1
            ];

            if (apiReg.Status__c != 'ACTIVE') {
                throw new APIException('API is not active');
            }

            HttpRequest request = new HttpRequest();
            request.setEndpoint(apiReg.Endpoint__c);
            request.setMethod(apiReg.HTTP_Method__c);
            request.setTimeout(30000);

            // Set headers
            if (headers != null && !headers.isEmpty()) {
                for (String headerName : headers.keySet()) {
                    request.setHeader(headerName, headers.get(headerName));
                }
            }

            // Set body for POST/PUT
            if (apiReg.HTTP_Method__c == 'POST' || apiReg.HTTP_Method__c == 'PUT') {
                if (parameters != null && !parameters.isEmpty()) {
                    request.setBody(JSON.serialize(parameters));
                    request.setHeader('Content-Type', 'application/json');
                }
            }

            Long startTime = System.currentTimeMillis();
            Http http = new Http();
            HttpResponse response = http.send(request);
            Long responseTime = System.currentTimeMillis() - startTime;

            // Log API call
            logAPICall(apiId, request, response, responseTime);

            result.put('success', true);
            result.put('statusCode', response.getStatusCode());
            result.put('responseBody', response.getBody());
            result.put('responseTime', responseTime);

        } catch (Exception e) {
            result.put('success', false);
            result.put('error', e.getMessage());
        }
        return result;
    }

    // ================== API List ==================
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getAPIList(String status) {
        List<Map<String, Object>> apis = new List<Map<String, Object>>();
        try {
            String query = 'SELECT Id, Name, Endpoint__c, HTTP_Method__c, Description__c, Status__c, Created_Date__c FROM API_Registration__c';
            if (String.isNotBlank(status)) {
                query += ' WHERE Status__c = :status';
            }
            query += ' ORDER BY Name ASC';

            List<API_Registration__c> apiList = Database.query(query);
            for (API_Registration__c api : apiList) {
                Map<String, Object> apiData = new Map<String, Object>();
                apiData.put('id', api.Id);
                apiData.put('name', api.Name);
                apiData.put('endpoint', api.Endpoint__c);
                apiData.put('method', api.HTTP_Method__c);
                apiData.put('description', api.Description__c);
                apiData.put('status', api.Status__c);
                apiData.put('createdDate', api.Created_Date__c);
                apis.add(apiData);
            }
        } catch (Exception e) {
            System.debug('Error retrieving API list: ' + e.getMessage());
        }
        return apis;
    }

    // ================== API Metrics ==================
    @AuraEnabled
    public static Map<String, Object> getAPIMetrics(String apiId, String timeframe) {
        Map<String, Object> metrics = new Map<String, Object>();
        try {
            DateTime startDate = calculateTimeframe(timeframe);

            // Get total + avg response time
            AggregateResult totalStats = [
                SELECT COUNT(Id) totalCalls, AVG(Response_Time__c) avgResponseTime
                FROM API_Call_Log__c
                WHERE API_Registration__c = :apiId
                AND Call_Date__c >= :startDate
            ];

            // Get successful calls (2xx)
            AggregateResult successStats = [
                SELECT COUNT(Id) successfulCalls
                FROM API_Call_Log__c
                WHERE API_Registration__c = :apiId
                AND Call_Date__c >= :startDate
                AND Status_Code__c >= 200 AND Status_Code__c < 300
            ];

            Integer total = (Integer)totalStats.get('totalCalls');
            Integer successful = (Integer)successStats.get('successfulCalls');

            metrics.put('totalCalls', total);
            metrics.put('successfulCalls', successful);
            metrics.put('failedCalls', total - successful);
            metrics.put('successRate', total > 0 ? (successful * 100.0 / total) : 0);
            metrics.put('averageResponseTime', totalStats.get('avgResponseTime'));

            // Error breakdown
            List<AggregateResult> errorStats = [
                SELECT Status_Code__c statusCode, COUNT(Id) errorCount
                FROM API_Call_Log__c
                WHERE API_Registration__c = :apiId
                AND Status_Code__c >= 400
                AND Call_Date__c >= :startDate
                GROUP BY Status_Code__c
            ];

            List<Map<String, Object>> errorBreakdown = new List<Map<String, Object>>();
            for (AggregateResult error : errorStats) {
                Map<String, Object> errorData = new Map<String, Object>();
                errorData.put('statusCode', error.get('statusCode'));
                errorData.put('count', error.get('errorCount'));
                errorBreakdown.add(errorData);
            }
            metrics.put('errorBreakdown', errorBreakdown);

            metrics.put('timeframe', timeframe);
            metrics.put('success', true);

        } catch (Exception e) {
            metrics.put('success', false);
            metrics.put('error', e.getMessage());
        }
        return metrics;
    }

    // ================== Update Status ==================
    @AuraEnabled
    public static Map<String, Object> updateAPIStatus(String apiId, String newStatus) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            API_Registration__c api = [
                SELECT Id, Status__c
                FROM API_Registration__c
                WHERE Id = :apiId
                LIMIT 1
            ];

            String oldStatus = api.Status__c;
            api.Status__c = newStatus;
            api.Last_Modified_Date__c = DateTime.now();
            update api;

            // Log status change
            logStatusChange(apiId, oldStatus, newStatus);

            result.put('success', true);
            result.put('message', 'API status updated from ' + oldStatus + ' to ' + newStatus);
        } catch (Exception e) {
            result.put('success', false);
            result.put('error', e.getMessage());
        }
        return result;
    }

    // ================== Endpoint Validation ==================
    @AuraEnabled
    public static Map<String, Object> validateAPIEndpoint(String endpoint, String method) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod(method);
            request.setTimeout(10000);

            Long startTime = System.currentTimeMillis();
            Http http = new Http();
            HttpResponse response = http.send(request);
            Long responseTime = System.currentTimeMillis() - startTime;

            result.put('success', true);
            result.put('statusCode', response.getStatusCode());
            result.put('responseTime', responseTime);
            result.put('isValid', response.getStatusCode() < 500);
            result.put('message', 'Endpoint validation completed');

        } catch (Exception e) {
            result.put('success', false);
            result.put('isValid', false);
            result.put('error', e.getMessage());
        }
        return result;
    }

    // ================== Call History ==================
    @AuraEnabled
    public static Map<String, Object> getAPICallHistory(String apiId, Integer limitCount) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            String query = 'SELECT Id, Call_Date__c, Status_Code__c, Response_Time__c, Request_Size__c, Response_Size__c ' +
                           'FROM API_Call_Log__c WHERE API_Registration__c = :apiId ' +
                           'ORDER BY Call_Date__c DESC';
            if (limitCount != null && limitCount > 0) {
                query += ' LIMIT ' + limitCount;
            }

            List<API_Call_Log__c> callHistory = Database.query(query);
            List<Map<String, Object>> calls = new List<Map<String, Object>>();

            for (API_Call_Log__c call : callHistory) {
                Map<String, Object> callData = new Map<String, Object>();
                callData.put('id', call.Id);
                callData.put('callDate', call.Call_Date__c);
                callData.put('statusCode', call.Status_Code__c);
                callData.put('responseTime', call.Response_Time__c);
                callData.put('requestSize', call.Request_Size__c);
                callData.put('responseSize', call.Response_Size__c);
                callData.put('success', call.Status_Code__c >= 200 && call.Status_Code__c < 300);
                calls.add(callData);
            }

            result.put('success', true);
            result.put('callHistory', calls);
            result.put('totalCalls', calls.size());

        } catch (Exception e) {
            result.put('success', false);
            result.put('error', e.getMessage());
        }
        return result;
    }

    // ================== Helper Methods ==================
    private static void logAPICall(String apiId, HttpRequest request, HttpResponse response, Long responseTime) {
        try {
            API_Call_Log__c log = new API_Call_Log__c(
                API_Registration__c = apiId,
                Call_Date__c = DateTime.now(),
                HTTP_Method__c = request.getMethod(),
                Status_Code__c = response.getStatusCode(),
                Response_Time__c = responseTime,
                Request_Size__c = request.getBody() != null ? request.getBody().length() : 0,
                Response_Size__c = response.getBody() != null ? response.getBody().length() : 0
            );
            insert log;
        } catch (Exception e) {
            System.debug('Failed to log API call: ' + e.getMessage());
        }
    }

    private static void logStatusChange(String apiId, String oldStatus, String newStatus) {
        try {
            API_Status_Change_Log__c log = new API_Status_Change_Log__c(
                API_Registration__c = apiId,
                Old_Status__c = oldStatus,
                New_Status__c = newStatus,
                Changed_By__c = UserInfo.getUserId(),
                Changed_Date__c = DateTime.now()
            );
            insert log;
        } catch (Exception e) {
            System.debug('Failed to log status change: ' + e.getMessage());
        }
    }

    private static DateTime calculateTimeframe(String timeframe) {
        switch on timeframe {
            when 'LAST_HOUR'      { return DateTime.now().addHours(-1); }
            when 'LAST_24_HOURS'  { return DateTime.now().addHours(-24); }
            when 'LAST_7_DAYS'    { return DateTime.now().addDays(-7); }
            when 'LAST_30_DAYS'   { return DateTime.now().addDays(-30); }
            when else             { return DateTime.now().addDays(-7); }
        }
    }

    // ================== Custom Exception ==================
    public class APIException extends Exception {}
}