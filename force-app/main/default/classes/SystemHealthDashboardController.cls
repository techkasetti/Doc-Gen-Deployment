public with sharing class SystemHealthDashboardController {
    // ========================
    // Public methods (LWC)
    // ========================

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDashboardData(String timeframe) {
        Map<String, Object> dashboardData = new Map<String, Object>();
        try {
            dashboardData.put('healthSummary', getSystemHealthSummary(timeframe));
           
            dashboardData.put('recentAlerts', getRecentAlerts(timeframe));
            dashboardData.put('performanceCharts', getPerformanceChartsData(timeframe));
            dashboardData.put('systemResources', getSystemResourcesStatus());
            dashboardData.put('complianceStatus', getComplianceStatus());
            dashboardData.put('success', true);
            dashboardData.put('lastUpdated', DateTime.now());
            return dashboardData;
        } catch (Exception e) {
            System.debug('Error in getDashboardData: ' + e.getMessage());
            throw new AuraHandledException('Failed to load dashboard data: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> executeSystemHealthCheck() {
        try {
            Map<String, Object> result = new Map<String, Object>();
            Map<String, Object> summary = getSystemHealthSummary(null);

            // Optionally persist snapshot if custom object exists (best-effort)
            try {
                if (Schema.getGlobalDescribe().containsKey('Performance_Snapshot__c')) {
                    SObject snap = Schema.getGlobalDescribe().get('Performance_Snapshot__c').newSObject();
                    Map<String, Schema.SObjectField> fMap = snap.getSObjectType().getDescribe().fields.getMap();
                    if (fMap.containsKey('Response_Time__c') && summary.containsKey('averageResponseTime')) {
                        snap.put('Response_Time__c', summary.get('averageResponseTime'));
                    }
                    if (fMap.containsKey('Error_Rate__c') && summary.containsKey('errorRate')) {
                        snap.put('Error_Rate__c', summary.get('errorRate'));
                    }
                    if (fMap.containsKey('Snapshot_Date__c')) {
                        snap.put('Snapshot_Date__c', DateTime.now());
                    }
                    insert snap;
                }
            } catch (Exception ex) {
                System.debug('Snapshot persistence skipped/failed: ' + ex.getMessage());
            }

            Decimal score = summary.containsKey('overallHealthScore') && summary.get('overallHealthScore') != null
                ? (Decimal) summary.get('overallHealthScore') : 0;
            Boolean isSuccessful = score >= 70;
            result.put('success', isSuccessful);
            result.put('healthScore', score);
            result.put('message', getHealthCheckMessage(score));
            result.put('recommendedActions', getRecommendedActionsFromSummary(summary));
            return result;
        } catch (Exception e) {
            System.debug('Error in executeSystemHealthCheck: ' + e.getMessage());
            throw new AuraHandledException('Health check failed: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> acknowledgeSystemAlert(String alertId, String acknowledgmentNotes) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            if (!Schema.getGlobalDescribe().containsKey('System_Alert__c')) {
                result.put('success', false);
                result.put('error', 'System_Alert__c not present in org');
                return result;
            }

            String safeId = String.escapeSingleQuotes(alertId);
            String q = 'SELECT Id, Status__c FROM System_Alert__c WHERE Id = \'' + safeId + '\' LIMIT 1';
            List<SObject> rows = Database.query(q);
            if (rows.isEmpty()) {
                result.put('success', false);
                result.put('error', 'Alert not found');
                return result;
            }
            SObject alert = rows[0];
            SObjectType at = alert.getSObjectType();
            Map<String, Schema.SObjectField> fields = at.getDescribe().fields.getMap();

            // Use dynamic put to avoid compile-time dependence on fields
            if (fields.containsKey('Status__c')) alert.put('Status__c', 'ACKNOWLEDGED');
            if (fields.containsKey('Acknowledged_By__c')) alert.put('Acknowledged_By__c', UserInfo.getUserId());
            if (fields.containsKey('Acknowledged_At__c')) alert.put('Acknowledged_At__c', DateTime.now());
            if (fields.containsKey('Acknowledgment_Notes__c')) alert.put('Acknowledgment_Notes__c', acknowledgmentNotes);
            update alert;

            createAuditTrail('ALERT_ACKNOWLEDGED', 'Alert acknowledged: ' + alertId, 'SUCCESS');

            result.put('success', true);
            result.put('message', 'Alert acknowledged successfully');
            return result;
        } catch (Exception e) {
            System.debug('Error acknowledging alert: ' + e.getMessage());
            throw new AuraHandledException('Failed to acknowledge alert: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> dismissAlert(String alertId, String dismissalReason) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            if (!Schema.getGlobalDescribe().containsKey('System_Alert__c')) {
                result.put('success', false);
                result.put('error', 'System_Alert__c not present in org');
                return result;
            }

            String safeId = String.escapeSingleQuotes(alertId);
            String q = 'SELECT Id, Status__c FROM System_Alert__c WHERE Id = \'' + safeId + '\' LIMIT 1';
            List<SObject> rows = Database.query(q);
            if (rows.isEmpty()) {
                result.put('success', false);
                result.put('error', 'Alert not found');
                return result;
            }
            SObject alert = rows[0];
            SObjectType at = alert.getSObjectType();
            Map<String, Schema.SObjectField> fields = at.getDescribe().fields.getMap();

            if (fields.containsKey('Status__c')) alert.put('Status__c', 'DISMISSED');
            if (fields.containsKey('Dismissed_By__c')) alert.put('Dismissed_By__c', UserInfo.getUserId());
            if (fields.containsKey('Dismissed_At__c')) alert.put('Dismissed_At__c', DateTime.now());
            if (fields.containsKey('Dismissal_Reason__c')) alert.put('Dismissal_Reason__c', dismissalReason);

            update alert;

            createAuditTrail('ALERT_DISMISSED', 'Alert dismissed: ' + alertId, 'SUCCESS');

            result.put('success', true);
            result.put('message', 'Alert dismissed successfully');
            return result;
        } catch (Exception e) {
            System.debug('Error dismissing alert: ' + e.getMessage());
            throw new AuraHandledException('Failed to dismiss alert: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> generateHealthReport(String timeframe, Boolean includeRecommendations) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            List<String> lines = new List<String>();
            lines.add('=== SYSTEM HEALTH REPORT ===');
            lines.add('Generated: ' + String.valueOf(DateTime.now()));
            lines.add('Report Period: ' + (String.isBlank(timeframe) ? 'default' : timeframe));
            lines.add('');

            Map<String, Object> healthData = getSystemHealthSummary(timeframe);

            lines.add('EXECUTIVE SUMMARY');
            lines.add('-----------------');
            lines.add('Overall Health Score: ' + String.valueOf(healthData.get('overallHealthScore')));
            lines.add('System Status: ' + String.valueOf(healthData.get('systemStatus')));
            lines.add('System Uptime (hrs): ' + String.valueOf(healthData.get('systemUptime')));
            lines.add('Error Rate (%): ' + String.valueOf(healthData.get('errorRate')));
            lines.add('');

            lines.add('COMPONENT STATUS');
            lines.add('----------------');

            System.debug(lines);

System.debug(lines);

            lines.add('');

            lines.add('PERFORMANCE METRICS');
            lines.add('-------------------');
            lines.add('Average Response Time (ms): ' + String.valueOf(healthData.get('averageResponseTime')));
            lines.add('Peak Response Time (ms): ' + String.valueOf(healthData.get('peakResponseTime')));
            lines.add('Throughput (req/min): ' + String.valueOf(healthData.get('throughput')));
            lines.add('');

            lines.add('RECENT ALERTS');
            lines.add('-------------');
            List<Map<String, Object>> recentAlerts = getActiveAlertsForReport(timeframe);
            for (Map<String, Object> a : recentAlerts) {
                lines.add('- [' + String.valueOf(a.get('severity')) + '] ' + String.valueOf(a.get('title')) + ': ' + String.valueOf(a.get('message')));
            }
            lines.add('');

            if (includeRecommendations) {
                lines.add('RECOMMENDATIONS');
                lines.add('---------------');
                List<String> recommendations = getRecommendedActionsFromSummary(healthData);
                for (String r : recommendations) lines.add('- ' + r);
                lines.add('');
            }

            result.put('success', true);
            result.put('report', String.join(lines, '\n'));
            result.put('message', 'Health report generated successfully');
            return result;
        } catch (Exception e) {
            System.debug('Error in generateHealthReport: ' + e.getMessage());
            throw new AuraHandledException('Failed to generate health report: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getPerformanceHistory(Integer days) {
        List<Map<String, Object>> performanceData = new List<Map<String, Object>>();
        try {
            DateTime startDate = DateTime.now().addDays((days == null) ? -7 : -Math.abs(days));
            if (!Schema.getGlobalDescribe().containsKey('Performance_Snapshot__c')) return performanceData;

            String q = 'SELECT Id, Snapshot_Date__c, Response_Time__c, Error_Rate__c, Throughput__c, System_Load__c, Memory_Usage__c '
                     + 'FROM Performance_Snapshot__c WHERE Snapshot_Date__c >= ' + formatDateTimeForSOQL(startDate)
                     + ' ORDER BY Snapshot_Date__c DESC LIMIT 500';
            List<SObject> snaps = Database.query(q);
            for (SObject so : snaps) {
                Map<String, Object> dp = new Map<String, Object>();
                dp.put('id', String.valueOf(so.get('Id')));
                dp.put('timestamp', so.get('Snapshot_Date__c'));
                dp.put('responseTime', so.get('Response_Time__c'));
                dp.put('errorRate', so.get('Error_Rate__c'));
                dp.put('throughput', so.get('Throughput__c'));
                dp.put('systemLoad', so.get('System_Load__c'));
                dp.put('memoryUsage', so.get('Memory_Usage__c'));
                performanceData.add(dp);
            }
            return performanceData;
        } catch (Exception e) {
            System.debug('Error in getPerformanceHistory: ' + e.getMessage());
            throw new AuraHandledException('Failed to load performance history: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getAdvancedAnalytics(String timeframe, String analyticsType) {
        Map<String, Object> analytics = new Map<String, Object>();
        try {
            DateTime startDate = getStartDateFromTimeframe(timeframe);
            if (analyticsType == null) analyticsType = '';
            switch on analyticsType.toUpperCase() {
                when 'PERFORMANCE' { analytics = getPerformanceAnalytics(startDate); }
                when 'USAGE' { analytics = getUsageAnalytics(startDate); }
                when 'SECURITY' { analytics = getSecurityAnalytics(startDate); }
                when 'CAPACITY' { analytics = getCapacityAnalytics(startDate); }
                when else { analytics = getComprehensiveAnalytics(startDate); }
            }
            analytics.put('success', true);
            analytics.put('lastUpdated', DateTime.now());
        } catch (Exception e) {
            System.debug('Error generating advanced analytics: ' + e.getMessage());
            analytics.put('success', false);
            analytics.put('error', e.getMessage());
        }
        return analytics;
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getPredictiveInsights() {
        Map<String, Object> insights = new Map<String, Object>();
        try {
            DateTime startDate = DateTime.now().addDays(-30);
            List<SObject> recentSnapshots = new List<SObject>();
            if (Schema.getGlobalDescribe().containsKey('Performance_Snapshot__c')) {
                String q = 'SELECT Response_Time__c, Error_Rate__c, Throughput__c, Snapshot_Date__c '
                         + 'FROM Performance_Snapshot__c WHERE Snapshot_Date__c >= ' + formatDateTimeForSOQL(startDate)
                         + ' ORDER BY Snapshot_Date__c DESC LIMIT 1000';
                recentSnapshots = Database.query(q);
            }
            insights.put('predictions', calculateTrendPredictions(recentSnapshots));
            insights.put('capacityRecommendations', generateCapacityRecommendations(recentSnapshots));
            insights.put('riskAssessment', performRiskAssessment(recentSnapshots));
            insights.put('optimizationSuggestions', generateOptimizationSuggestions(recentSnapshots));
            insights.put('success', true);
            insights.put('generatedAt', DateTime.now());
        } catch (Exception e) {
            System.debug('Error generating predictive insights: ' + e.getMessage());
            insights.put('success', false);
            insights.put('error', e.getMessage());
        }
        return insights;
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> scheduleHealthCheck(String frequency, List<String> components) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            String cronExpression = getCronExpression(frequency);
            HealthCheckSchedulable job = new HealthCheckSchedulable(components);
            String jobId = System.schedule('System Health Check - ' + String.valueOf(DateTime.now().getTime()), cronExpression, job);
            result.put('success', true);
            result.put('jobId', jobId);
            result.put('message', 'Health check scheduled successfully');
        } catch (Exception e) {
            System.debug('Error scheduling health check: ' + e.getMessage());
            result.put('success', false);
            result.put('error', e.getMessage());
        }
        return result;
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> executeEmergencyRecovery(String recoveryType, Map<String, Object> parameters) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            switch on recoveryType {
                when 'CACHE_CLEAR' { result = executeCacheClearRecovery(parameters); }
                when 'SERVICE_RESTART' { result = executeServiceRestartRecovery(parameters); }
                when 'DATABASE_OPTIMIZATION' { result = executeDatabaseOptimizationRecovery(parameters); }
                when 'EMERGENCY_MAINTENANCE' { result = executeEmergencyMaintenanceRecovery(parameters); }
                when else {
                    result.put('success', false);
                    result.put('error', 'Unknown recovery type: ' + recoveryType);
                }
            }
        } catch (Exception e) {
            System.debug('Error executing emergency recovery: ' + e.getMessage());
            result.put('success', false);
            result.put('error', e.getMessage());
        }
        return result;
    }

    // ========================
    // Private helper methods
    // ========================

    private static Map<String, Object> getSystemHealthSummary(String timeframe) {
        Map<String, Object> summary = new Map<String, Object>();
        try {
            DateTime start1h = DateTime.now().addHours(-1);
            // Average response time from Performance_Log__c (best-effort)
            Decimal avgResponseTime = safeAggregateDecimal('Performance_Log__c', 'AVG(Response_Time_Ms__c)', start1h);
            Decimal peakResponseTime = safeAggregateDecimal('Performance_Log__c', 'MAX(Response_Time_Ms__c)', start1h);
            Decimal throughput = safeAggregateDecimal('Performance_Log__c', 'COUNT(Id)', start1h);
            Decimal errorRate = safeAggregateDecimal('System_Operation_Log__c', 'CASE WHEN SUM(CASE WHEN Status__c = \'ERROR\' THEN 1 ELSE 0 END) IS NULL OR SUM(CASE WHEN Status__c = \'ERROR\' THEN 1 ELSE 0 END) = 0 THEN 0 ELSE (SUM(CASE WHEN Status__c = \'ERROR\' THEN 1 ELSE 0 END) / NULLIF(COUNT(Id),0)) * 100 END', start1h);
            Decimal uptimePercent = calculateSystemUptimePercent();

            Decimal basicScore = 100;
            if (avgResponseTime > 5000) basicScore -= 40;
            else if (avgResponseTime > 3000) basicScore -= 20;
            else if (avgResponseTime > 2000) basicScore -= 10;
            if (errorRate > 5) basicScore -= 30; else if (errorRate > 2) basicScore -= 15; else if (errorRate > 1) basicScore -= 5;
            if (uptimePercent < 95) basicScore -= 30; else if (uptimePercent < 98) basicScore -= 15; else if (uptimePercent < 99.5) basicScore -= 5;

            summary.put('overallHealthScore', Math.max(basicScore, 0));
            summary.put('systemStatus', getSystemStatusFromScore(basicScore));
            summary.put('systemUptime', uptimePercent);
            summary.put('averageResponseTime', avgResponseTime);
            summary.put('peakResponseTime', peakResponseTime);
            summary.put('throughput', throughput);
            summary.put('errorRate', errorRate);
        } catch (Exception e) {
            System.debug('Error computing health summary: ' + e.getMessage());
            summary.put('overallHealthScore', 50);
            summary.put('systemStatus', 'UNKNOWN');
        }
        return summary;
    }

  

    private static List<Map<String, Object>> getRecentAlerts(String timeframe) {
        return getActiveAlertsForReport(timeframe);
    }

    private static Map<String, Object> getPerformanceChartsData(String timeframe) {
        Map<String, Object> out = new Map<String, Object>();
        try {
            DateTime start = getStartDateFromTimeframe(timeframe);
            if (!Schema.getGlobalDescribe().containsKey('Performance_Metric__c')) {
                out.put('executionTimeSeries', new List<Map<String,Object>>());
                return out;
            }
            String q = 'SELECT CALENDAR_HOUR(Timestamp__c) h, AVG(Execution_Time__c) avgTime, COUNT(Id) cnt '
                     + 'FROM Performance_Metric__c WHERE Timestamp__c >= ' + formatDateTimeForSOQL(start)
                     + ' GROUP BY CALENDAR_HOUR(Timestamp__c) ORDER BY CALENDAR_HOUR(Timestamp__c)';
            List<AggregateResult> ar = Database.query(q);
            List<Map<String,Object>> series = new List<Map<String,Object>>();
            for (AggregateResult r : ar) {
                Map<String,Object> pt = new Map<String,Object>();
                pt.put('hour', r.get('h'));
                pt.put('avgTime', r.get('avgTime'));
                pt.put('count', r.get('cnt'));
                series.add(pt);
            }
            out.put('executionTimeSeries', series);
        } catch (Exception e) {
            out.put('error', e.getMessage());
        }
        return out;
    }

    private static Map<String, Object> getSystemResourcesStatus() {
        Map<String, Object> res = new Map<String, Object>();
        try {
            Map<String, Object> gov = new Map<String, Object>();
            gov.put('soqlQueries', String.valueOf(Limits.getQueries()) + '/' + String.valueOf(Limits.getLimitQueries()));
            gov.put('cpuTime', String.valueOf(Limits.getCpuTime()) + '/' + String.valueOf(Limits.getLimitCpuTime()));
            res.put('governorLimits', gov);

            if (Schema.getGlobalDescribe().containsKey('Performance_Snapshot__c')) {
                String q = 'SELECT Memory_Usage__c, System_Load__c FROM Performance_Snapshot__c ORDER BY Snapshot_Date__c DESC LIMIT 1';
                List<SObject> snaps = Database.query(q);
                if (!snaps.isEmpty()) {
                    SObject s = snaps[0];
                    res.put('memoryUsage', s.get('Memory_Usage__c'));
                    res.put('systemLoad', s.get('System_Load__c'));
                }
            }
        } catch (Exception e) {
            res.put('error', e.getMessage());
        }
        return res;
    }

    private static Map<String, Object> getComplianceStatus() {
        Map<String, Object> out = new Map<String, Object>();
        try {
            if (Schema.getGlobalDescribe().containsKey('Compliance_Summary__c')) {
                String q = 'SELECT Overall_Compliance_Score__c, Last_Validation__c FROM Compliance_Summary__c ORDER BY Last_Validation__c DESC LIMIT 1';
                List<SObject> rows = Database.query(q);
                if (!rows.isEmpty()) {
                    SObject s = rows[0];
                    out.put('overallComplianceScore', s.get('Overall_Compliance_Score__c'));
                    out.put('lastValidation', s.get('Last_Validation__c'));
                }
            } else {
                out.put('overallComplianceScore', null);
                out.put('lastValidation', null);
            }
        } catch (Exception e) {
            out.put('error', e.getMessage());
        }
        return out;
    }

    // -----------------------
    // Utility & small helpers
    // -----------------------

    private static String getHealthCheckMessage(Decimal score) {
        if (score >= 95) return 'Excellent health';
        if (score >= 85) return 'Good health';
        if (score >= 70) return 'Fair health';
        return 'Needs attention';
    }

    private static List<String> getRecommendedActionsFromSummary(Map<String, Object> summary) {
        List<String> recs = new List<String>();
        try {
            Decimal art = summary.containsKey('averageResponseTime') && summary.get('averageResponseTime') != null ? (Decimal) summary.get('averageResponseTime') : null;
            Decimal er = summary.containsKey('errorRate') && summary.get('errorRate') != null ? (Decimal) summary.get('errorRate') : null;
            Decimal up = summary.containsKey('systemUptime') && summary.get('systemUptime') != null ? (Decimal) summary.get('systemUptime') : null;
            if (art != null && art > 3000) recs.add('Investigate slow endpoints and optimize queries/processes.');
            if (er != null && er > 2) recs.add('Investigate error spikes and introduce resilient retries / validations.');
            if (up != null && up < 99.5) recs.add('Review availability and failover strategies.');
            if (recs.isEmpty()) recs.add('No immediate recommendations; continue monitoring.');
        } catch (Exception e) {
            recs.add('Recommendation generation failed: ' + e.getMessage());
        }
        return recs;
    }

    private static List<Map<String,Object>> getActiveAlertsForReport(String timeframe) {
        List<Map<String,Object>> alerts = new List<Map<String,Object>>();
        try {
            if (!Schema.getGlobalDescribe().containsKey('System_Alert__c')) return alerts;
            DateTime start = getStartDateFromTimeframe(timeframe);
            String q = 'SELECT Id, Alert_Type__c, Severity__c, Message__c, Component__c, CreatedDate FROM System_Alert__c '
                     + 'WHERE Status__c = \'ACTIVE\' AND CreatedDate >= ' + formatDateTimeForSOQL(start)
                     + ' ORDER BY CreatedDate DESC LIMIT 50';
            List<SObject> rows = Database.query(q);
            for (SObject a : rows) {
                Map<String,Object> m = new Map<String,Object>();
                m.put('id', String.valueOf(a.get('Id')));
                m.put('title', a.get('Alert_Type__c'));
                m.put('message', a.get('Message__c'));
                m.put('severity', a.get('Severity__c'));
                m.put('component', a.get('Component__c'));
                m.put('time', a.get('CreatedDate'));
                alerts.add(m);
            }
        } catch (Exception e) {
            System.debug('getActiveAlertsForReport error: ' + e.getMessage());
        }
        return alerts;
    }

    private static Map<String,Object> createComponentHealth(String name, Boolean isHealthy) {
        Map<String,Object> m = new Map<String,Object>();
        m.put('componentName', name);
        m.put('status', isHealthy ? 'Healthy' : 'Degraded');
        m.put('healthScore', isHealthy ? 100 : 50);
        m.put('statusVariant', isHealthy ? 'success' : 'warning');
        return m;
    }

    // Best-effort component checks (dynamic queries or safe heuristics)
    private static Boolean checkDocGenHealth() {
        try {
            if (!Schema.getGlobalDescribe().containsKey('System_Operation_Log__c')) return true;
            String q = 'SELECT COUNT(Id) cnt FROM System_Operation_Log__c WHERE Operation_Type__c = \'DOCUMENT_GENERATION\' '
                     + 'AND Status__c = \'ERROR\' AND CreatedDate >= ' + formatDateTimeForSOQL(DateTime.now().addHours(-1));
            List<AggregateResult> ar = Database.query(q);
            if (!ar.isEmpty()) {
                Object cnt = ar[0].get('cnt');
                if (cnt != null) return ((Decimal)cnt).intValue() < 5;
            }
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private static Boolean checkSignatureHealth() {
        try {
            if (!Schema.getGlobalDescribe().containsKey('System_Operation_Log__c')) return true;
            String q = 'SELECT COUNT(Id) cnt FROM System_Operation_Log__c WHERE Operation_Type__c = \'SIGNATURE_REQUEST\' '
                     + 'AND Status__c = \'ERROR\' AND CreatedDate >= ' + formatDateTimeForSOQL(DateTime.now().addHours(-1));
            List<AggregateResult> ar = Database.query(q);
            if (!ar.isEmpty()) {
                Object cnt = ar[0].get('cnt');
                if (cnt != null) return ((Decimal)cnt).intValue() < 3;
            }
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    private static Boolean checkDatabaseHealth() {
        try {
            // Basic describe check
            return Schema.getGlobalDescribe().size() > 0;
        } catch (Exception e) {
            return false;
        }
    }

    private static Boolean checkApiHealth() {
        try {
            if (!Schema.getGlobalDescribe().containsKey('API_Call_Log__c')) return true;
            String q = 'SELECT AVG(Response_Time_Ms__c) avgTime FROM API_Call_Log__c WHERE CreatedDate >= ' + formatDateTimeForSOQL(DateTime.now().addMinutes(-15));
            List<AggregateResult> ar = Database.query(q);
            if (!ar.isEmpty() && ar[0].get('avgTime') != null) {
                Decimal avgTime = (Decimal) ar[0].get('avgTime');
                return avgTime < 5000;
            }
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    // -----------------------
    // Analytics helpers
    // -----------------------

    private static Map<String,Object> getPerformanceAnalytics(DateTime start) {
        Map<String,Object> out = new Map<String,Object>();
        try {
            if (!Schema.getGlobalDescribe().containsKey('Performance_Metric__c')) {
                out.put('note', 'Performance_Metric__c not present');
                return out;
            }
            String q = 'SELECT AVG(Execution_Time__c) avgExec, AVG(CPU_Time_Used__c) avgCpu, COUNT(Id) total '
                     + 'FROM Performance_Metric__c WHERE Timestamp__c >= ' + formatDateTimeForSOQL(start);
            List<AggregateResult> ar = Database.query(q);
            if (!ar.isEmpty()) {
                out.put('averageExecutionTime', ar[0].get('avgExec'));
                out.put('averageCpu', ar[0].get('avgCpu'));
                out.put('totalOperations', ar[0].get('total'));
            }
        } catch (Exception e) {
            out.put('error', e.getMessage());
        }
        return out;
    }

    private static Map<String,Object> getUsageAnalytics(DateTime start) {
        Map<String,Object> out = new Map<String,Object>();
        try {
            if (!Schema.getGlobalDescribe().containsKey('Document_Generation_Audit__c')) {
                out.put('note', 'Document_Generation_Audit__c not present');
                return out;
            }
            String q = 'SELECT COUNT_DISTINCT(CreatedById) activeUsers, COUNT(Id) totalActions FROM Document_Generation_Audit__c WHERE CreatedDate >= ' + formatDateTimeForSOQL(start);
            List<AggregateResult> ar = Database.query(q);
            if (!ar.isEmpty()) {
                out.put('activeUsers', ar[0].get('activeUsers'));
                out.put('totalActions', ar[0].get('totalActions'));
            }
        } catch (Exception e) {
            out.put('error', e.getMessage());
        }
        return out;
    }

    private static Map<String,Object> getSecurityAnalytics(DateTime start) {
        Map<String,Object> out = new Map<String,Object>();
        try {
            out.put('recentSecurityAlerts', getActiveAlertsForReport(null));
        } catch (Exception e) {
            out.put('error', e.getMessage());
        }
        return out;
    }

    private static Map<String,Object> getCapacityAnalytics(DateTime start) {
        Map<String,Object> out = new Map<String,Object>();
        try {
            if (!Schema.getGlobalDescribe().containsKey('Performance_Snapshot__c')) {
                out.put('note', 'Performance_Snapshot__c not present');
                return out;
            }
            String q = 'SELECT Throughput__c FROM Performance_Snapshot__c WHERE Snapshot_Date__c >= ' + formatDateTimeForSOQL(start) + ' ORDER BY Snapshot_Date__c DESC LIMIT 1';
            List<SObject> snaps = Database.query(q);
            if (!snaps.isEmpty()) out.put('currentThroughput', snaps[0].get('Throughput__c'));
        } catch (Exception e) {
            out.put('error', e.getMessage());
        }
        return out;
    }

    private static Map<String,Object> getComprehensiveAnalytics(DateTime start) {
        Map<String,Object> out = new Map<String,Object>();
        out.put('performance', getPerformanceAnalytics(start));
        out.put('usage', getUsageAnalytics(start));
        out.put('security', getSecurityAnalytics(start));
        out.put('capacity', getCapacityAnalytics(start));
        return out;
    }

    // Simple predictive placeholders (single definitions only)
    private static List<Object> calculateTrendPredictions(List<SObject> recentSnapshots) {
        List<Object> preds = new List<Object>();
        preds.add(new Map<String,Object>{ 'note' => 'Prediction engine not configured (placeholder)'});
        return preds;
    }

    private static List<String> generateCapacityRecommendations(List<SObject> recentSnapshots) {
        return new List<String>{ 'Review capacity if throughput trending upward.' };
    }

    private static Map<String,Object> performRiskAssessment(List<SObject> recentSnapshots) {
        Map<String,Object> r = new Map<String,Object>();
        r.put('risk', 'LOW');
        return r;
    }

    private static List<String> generateOptimizationSuggestions(List<SObject> recentSnapshots) {
        return new List<String>{ 'Consider caching hot results', 'Profile CPU-intensive operations' };
    }

    // -----------------------
    // Recovery stubs
    // -----------------------
    private static Map<String,Object> executeCacheClearRecovery(Map<String,Object> params) {
        Map<String,Object> r = new Map<String,Object>();
        r.put('success', true);
        r.put('message', 'Cache cleared (placeholder)');
        return r;
    }
    private static Map<String,Object> executeServiceRestartRecovery(Map<String,Object> params) {
        Map<String,Object> r = new Map<String,Object>();
        r.put('success', false);
        r.put('error', 'Service restart not supported in Apex; perform externally.');
        return r;
    }
    private static Map<String,Object> executeDatabaseOptimizationRecovery(Map<String,Object> params) {
        Map<String,Object> r = new Map<String,Object>();
        r.put('success', false);
        r.put('error', 'Database optimization must be performed outside of Apex.');
        return r;
    }
    private static Map<String,Object> executeEmergencyMaintenanceRecovery(Map<String,Object> params) {
        Map<String,Object> r = new Map<String,Object>();
        r.put('success', false);
        r.put('error', 'Emergency maintenance flow requires custom implementation.');
        return r;
    }

    // -----------------------
    // Common helpers: dynamic aggregate and formatting
    // -----------------------
    private static Decimal safeAggregateDecimal(String sObjectName, String aggregateExpr, DateTime since) {
        Decimal out = 0;
        try {
            if (!Schema.getGlobalDescribe().containsKey(sObjectName)) return out;
            String q = 'SELECT ' + aggregateExpr + ' val FROM ' + sObjectName + ' WHERE CreatedDate >= ' + formatDateTimeForSOQL(since);
            List<AggregateResult> ar = Database.query(q);
            if (!ar.isEmpty() && ar[0].get('val') != null) {
                Object v = ar[0].get('val');
                if (v instanceof Decimal) out = (Decimal) v;
                else if (v instanceof Integer) out = Decimal.valueOf((Integer)v);
                else out = Decimal.valueOf(String.valueOf(v));
            }
        } catch (Exception e) {
            System.debug('safeAggregateDecimal error: ' + e.getMessage());
        }
        return out;
    }

    private static String formatDateTimeForSOQL(DateTime dt) {
        if (dt == null) dt = DateTime.now();
        // ISO 8601 with Z timezone using GMT formatting
        return '\'' + dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + '\'';
    }

    private static DateTime getStartDateFromTimeframe(String timeframe) {
        if (String.isBlank(timeframe)) return DateTime.now().addDays(-7);
        String tf = timeframe.trim().toLowerCase();
        try {
            if (tf.endsWith('h')) {
                Integer h = Integer.valueOf(tf.substring(0, tf.length()-1));
                return DateTime.now().addHours(-h);
            } else if (tf.endsWith('d')) {
                Integer d = Integer.valueOf(tf.substring(0, tf.length()-1));
                return DateTime.now().addDays(-d);
            } else {
                Integer d = Integer.valueOf(tf);
                return DateTime.now().addDays(-d);
            }
        } catch (Exception e) {
            return DateTime.now().addDays(-7);
        }
    }

    private static Decimal calculateSystemUptimePercent() {
        try {
            if (!Schema.getGlobalDescribe().containsKey('System_Alert__c')) return 100;
            DateTime since = DateTime.now().addHours(-24);
            String q = 'SELECT Duration_Minutes__c d FROM System_Alert__c WHERE CreatedDate >= ' + formatDateTimeForSOQL(since) + ' AND Alert_Type__c = \'SYSTEM_DOWN\'';
            List<SObject> downtime = Database.query(q);
            Integer downMinutes = 0;
            for (SObject so : downtime) {
                Object dm = so.get('Duration_Minutes__c');
                if (dm != null) {
                    Integer i = 0;
                    try { i = Integer.valueOf(String.valueOf(dm)); } catch (Exception ex) { i = 0; }
                    downMinutes += i;
                }
            }
            Integer totalMinutes = 24 * 60;
            Integer upMinutes = Math.max(0, totalMinutes - downMinutes);
            return (Decimal.valueOf(upMinutes) / Decimal.valueOf(totalMinutes)) * 100;
        } catch (Exception e) {
            return 100;
        }
    }

    private static String getSystemStatusFromScore(Decimal score) {
        if (score >= 95) return 'Excellent';
        if (score >= 85) return 'Good';
        if (score >= 70) return 'Fair';
        return 'Needs Attention';
    }

    private static void createAuditTrail(String action, String details, String status) {
        try {
            if (!Schema.getGlobalDescribe().containsKey('AuditTrail__c')) return;
            SObject a = Schema.getGlobalDescribe().get('AuditTrail__c').newSObject();
            Map<String, Schema.SObjectField> f = a.getSObjectType().getDescribe().fields.getMap();
            if (f.containsKey('Action__c')) a.put('Action__c', action);
            if (f.containsKey('Details__c')) a.put('Details__c', details);
            if (f.containsKey('Status__c')) a.put('Status__c', status);
            if (f.containsKey('User_Id__c')) a.put('User_Id__c', UserInfo.getUserId());
            if (f.containsKey('Timestamp__c')) a.put('Timestamp__c', DateTime.now());
            insert a;
        } catch (Exception e) {
            System.debug('createAuditTrail failed: ' + e.getMessage());
        }
    }

    // -----------------------
    // Simple scheduling class
    // -----------------------
    public class HealthCheckSchedulable implements Schedulable {
        private List<String> components;
        public HealthCheckSchedulable() { this.components = new List<String>(); }
        public HealthCheckSchedulable(List<String> components) { this.components = components == null ? new List<String>() : components; }
        public void execute(SchedulableContext sc) {
            try {
                Map<String,Object> summary = getSystemHealthSummary(null);
                createAuditTrail('SCHEDULED_HEALTH_CHECK', 'Score: ' + String.valueOf(summary.get('overallHealthScore')), 'SUCCESS');
            } catch (Exception e) {
                createAuditTrail('SCHEDULED_HEALTH_CHECK', 'Failed: ' + e.getMessage(), 'ERROR');
            }
        }
    }

    // -----------------------
    // Small utility methods
    // -----------------------
    private static String getCronExpression(String frequency) {
        if (String.isBlank(frequency)) return '0 0 0 * * ?'; // daily
        String f = frequency.toLowerCase();
        if (f == 'hourly') return '0 0 * * * ?';
        if (f == 'daily') return '0 0 0 * * ?';
        if (f == 'weekly') return '0 0 0 ? * MON';
        return '0 0 0 * * ?';
    }

   
}