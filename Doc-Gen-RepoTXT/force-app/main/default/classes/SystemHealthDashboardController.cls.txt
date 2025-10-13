// SystemHealthDashboardController - Apex Controller for the LWC
public with sharing class SystemHealthDashboardController {
    
    // ================================
    // Public Methods
    // ================================
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDashboardData(String timeframe) {
        try {
            Map<String, Object> dashboardData = new Map<String, Object>();
            
            // Collect dashboard sections
            dashboardData.put('healthSummary', getSystemHealthSummary());
            dashboardData.put('componentHealth', getComponentHealthStatus());
            dashboardData.put('recentAlerts', getRecentAlerts(timeframe));
            dashboardData.put('performanceCharts', getPerformanceChartsData(timeframe));
            dashboardData.put('systemResources', getSystemResourcesStatus());
            dashboardData.put('complianceStatus', getComplianceStatus());
            
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
            
            // Execute comprehensive health check
            SystemHealthMonitor.SystemHealthWrapper healthResult = 
                SystemHealthMonitor.getCompleteSystemHealth();
            
            // Create snapshot
            SystemHealthMonitor.createHealthSnapshot(healthResult);
            
            Boolean isSuccessful = healthResult.overallHealthScore >= 70;
            
            result.put('success', isSuccessful);
            result.put('healthScore', healthResult.overallHealthScore);
            result.put('message', getHealthCheckMessage(healthResult.overallHealthScore));
            result.put('recommendedActions', getRecommendedActions(healthResult));
            
            return result;
        } catch (Exception e) {
            System.debug('Error in executeSystemHealthCheck: ' + e.getMessage());
            throw new AuraHandledException('Health check failed: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Map<String, Object> acknowledgeSystemAlert(String alertId, String acknowledgmentNotes) {
        try {
            Map<String, Object> result = new Map<String, Object>();
            
            System_Alert__c alert = [
                SELECT Id, Status__c, Acknowledged_By__c, Acknowledged_At__c 
                FROM System_Alert__c 
                WHERE Id = :alertId 
                LIMIT 1
            ];
            
            alert.Status__c = 'ACKNOWLEDGED';
            alert.Acknowledged_By__c = UserInfo.getUserId();
            alert.Acknowledged_At__c = DateTime.now();
            alert.Acknowledgment_Notes__c = acknowledgmentNotes;
            
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
        try {
            Map<String, Object> result = new Map<String, Object>();
            
            System_Alert__c alert = [
                SELECT Id, Status__c, Dismissed_By__c, Dismissed_At__c 
                FROM System_Alert__c 
                WHERE Id = :alertId 
                LIMIT 1
            ];
            
            alert.Status__c = 'DISMISSED';
            alert.Dismissed_By__c = UserInfo.getUserId();
            alert.Dismissed_At__c = DateTime.now();
            alert.Dismissal_Reason__c = dismissalReason;
            
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
        try {
            Map<String, Object> result = new Map<String, Object>();
            StringBuilder report = new StringBuilder();
            
            // Report header
            report.append('=== SYSTEM HEALTH REPORT ===\n');
            report.append('Generated: ' + String.valueOf(DateTime.now()) + '\n');
            report.append('Report Period: ' + timeframe + '\n\n');
            
            SystemHealthMonitor.SystemHealthWrapper healthData = SystemHealthMonitor.getCompleteSystemHealth();
            
            // Executive summary
            report.append('EXECUTIVE SUMMARY\n');
            report.append('================\n');
            report.append('Overall Health Score: ' + healthData.overallHealthScore + '%\n');
            report.append('System Status: ' + healthData.systemStatus + '\n');
            report.append('System Uptime: ' + healthData.uptime + ' hours\n');
            report.append('Error Rate: ' + healthData.errorRate + '%\n\n');
            
            // Component status
            report.append('COMPONENT STATUS\n');
            report.append('================\n');
            for (SystemHealthMonitor.ComponentHealth component : healthData.componentHealthList) {
                report.append('- ' + component.componentName + ': ' + component.status);
                report.append(' (Health: ' + component.healthScore + '%)\n');
            }
            report.append('\n');
            
            // Performance metrics
            report.append('PERFORMANCE METRICS\n');
            report.append('===================\n');
            report.append('Average Response Time: ' + healthData.averageResponseTime + 'ms\n');
            report.append('Peak Response Time: ' + healthData.peakResponseTime + 'ms\n');
            report.append('Throughput: ' + healthData.throughput + ' requests/minute\n\n');
            
            // Recent alerts
            List<System_Alert__c> recentAlerts = getActiveAlertsForReport(timeframe);
            report.append('RECENT ALERTS (' + recentAlerts.size() + ' total)\n');
            report.append('=============\n');
            for (System_Alert__c alert : recentAlerts) {
                report.append('- [' + alert.Severity__c + '] ' + alert.Alert_Type__c);
                report.append(': ' + alert.Message__c + '\n');
            }
            report.append('\n');
            
            // Recommendations
            if (includeRecommendations) {
                report.append('RECOMMENDATIONS\n');
                report.append('===============\n');
                List<String> recommendations = generateHealthRecommendations(healthData);
                for (String recommendation : recommendations) {
                    report.append('- ' + recommendation + '\n');
                }
            }
            
            result.put('success', true);
            result.put('report', report.toString());
            result.put('message', 'Health report generated successfully');
            return result;
        } catch (Exception e) {
            System.debug('Error in generateHealthReport: ' + e.getMessage());
            throw new AuraHandledException('Failed to generate health report: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getPerformanceHistory(Integer days) {
        try {
            List<Map<String, Object>> performanceData = new List<Map<String, Object>>();
            DateTime startDate = DateTime.now().addDays(-days);
            
            List<Performance_Snapshot__c> snapshots = [
                SELECT Id, Snapshot_Date__c, Response_Time__c, Error_Rate__c, 
                       Throughput__c, System_Load__c, Memory_Usage__c
                FROM Performance_Snapshot__c 
                WHERE Snapshot_Date__c >= :startDate
                ORDER BY Snapshot_Date__c DESC
                LIMIT 500
            ];
            
            for (Performance_Snapshot__c snapshot : snapshots) {
                Map<String, Object> dataPoint = new Map<String, Object>();
                dataPoint.put('id', snapshot.Id);
                dataPoint.put('timestamp', snapshot.Snapshot_Date__c);
                dataPoint.put('responseTime', snapshot.Response_Time__c);
                dataPoint.put('errorRate', snapshot.Error_Rate__c);
                dataPoint.put('throughput', snapshot.Throughput__c);
                dataPoint.put('systemLoad', snapshot.System_Load__c);
                dataPoint.put('memoryUsage', snapshot.Memory_Usage__c);
                performanceData.add(dataPoint);
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
        switch on analyticsType {
            when 'PERFORMANCE' { analytics = getPerformanceAnalytics(startDate); }
            when 'USAGE'       { analytics = getUsageAnalytics(startDate); }
            when 'SECURITY'    { analytics = getSecurityAnalytics(startDate); }
            when 'CAPACITY'    { analytics = getCapacityAnalytics(startDate); }
            when else          { analytics = getComprehensiveAnalytics(startDate); }
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
        List<Performance_Snapshot__c> recentSnapshots = [
            SELECT Response_Time__c, Error_Rate__c, Throughput__c, Snapshot_Date__c
            FROM Performance_Snapshot__c 
            WHERE Snapshot_Date__c >= :DateTime.now().addDays(-30)
            ORDER BY Snapshot_Date__c DESC
            LIMIT 1000
        ];
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
        HealthCheckScheduler scheduler = new HealthCheckScheduler();
        scheduler.setComponents(components);
        String jobId = System.schedule(
            'System Health Check - ' + DateTime.now().format(),
            cronExpression,
            scheduler
        );
        System_Health_Schedule__c schedule = new System_Health_Schedule__c(
            Name = 'Health Check - ' + frequency,
            Job_Id__c = jobId,
            Frequency__c = frequency,
            Components__c = String.join(components, ';'),
            Status__c = 'ACTIVE',
            Next_Run_Time__c = getNextRunTime(cronExpression)
        );
        insert schedule;
        result.put('success', true);
        result.put('jobId', jobId);
        result.put('scheduleId', schedule.Id);
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
        Emergency_Recovery_Log__c recoveryLog = new Emergency_Recovery_Log__c(
            Recovery_Type__c = recoveryType,
            Initiated_By__c = UserInfo.getUserId(),
            Status__c = 'IN_PROGRESS',
            Parameters__c = JSON.serialize(parameters)
        );
        insert recoveryLog;
        switch on recoveryType {
            when 'CACHE_CLEAR'           { result = executeCacheClearRecovery(parameters); }
            when 'SERVICE_RESTART'       { result = executeServiceRestartRecovery(parameters); }
            when 'DATABASE_OPTIMIZATION' { result = executeDatabaseOptimizationRecovery(parameters); }
            when 'EMERGENCY_MAINTENANCE' { result = executeEmergencyMaintenanceRecovery(parameters); }
            when else { throw new IllegalArgumentException('Unknown recovery type: ' + recoveryType); }
        }
        recoveryLog.Status__c = (Boolean)result.get('success') ? 'COMPLETED' : 'FAILED';
        recoveryLog.Result__c = JSON.serialize(result);
        recoveryLog.Completed_At__c = DateTime.now();
        update recoveryLog;
    } catch (Exception e) {
        System.debug('Error executing emergency recovery: ' + e.getMessage());
        result.put('success', false);
        result.put('error', e.getMessage());
    }
    return result;
}
@AuraEnabled(cacheable=false)
public static Map<String, Object> getDashboardData() {
    Map<String, Object> dashboardData = new Map<String, Object>();
    try {
        dashboardData.put('healthSummary', getHealthSummary());
        dashboardData.put('componentHealth', getComponentHealth());
        dashboardData.put('recentAlerts', getCriticalAlerts());
        dashboardData.put('performanceMetrics', getBasicPerformanceMetrics());
        dashboardData.put('success', true);
        dashboardData.put('lastUpdated', DateTime.now());
    } catch (Exception e) {
        System.debug('Dashboard error: ' + e.getMessage());
        dashboardData.put('success', false);
        dashboardData.put('error', e.getMessage());
    }
    return dashboardData;
}

@AuraEnabled(cacheable=false)
public static Map<String, Object> acknowledgeSystemAlert(String alertId, String notes) {
    Map<String, Object> result = new Map<String, Object>();
    try {
        System_Alert__c alert = [
            SELECT Id, Status__c
            FROM System_Alert__c
            WHERE Id = :alertId
            LIMIT 1
        ];
        alert.Status__c = 'ACKNOWLEDGED';
        alert.Acknowledged_By__c = UserInfo.getUserId();
        alert.Acknowledged_Date__c = DateTime.now();
        alert.Acknowledgment_Notes__c = notes;
        update alert;

        result.put('success', true);
        result.put('message', 'Alert acknowledged successfully');
    } catch (Exception e) {
        result.put('success', false);
        result.put('message', e.getMessage());
    }
    return result;
}

@AuraEnabled(cacheable=false)
public static Map<String, Object> executeHealthCheck() {
    Map<String, Object> result = new Map<String, Object>();
    try {
        SystemHealthMonitor.HealthCheckResult healthCheck =
            SystemHealthMonitor.performComprehensiveHealthCheck();
        result.put('success', true);
        result.put('healthCheck', healthCheck);
        result.put('timestamp', DateTime.now());
    } catch (Exception e) {
        result.put('success', false);
        result.put('error', e.getMessage());
    }
    return result;
}

// ---------- Private Helpers ----------

private static Map<String, Object> getHealthSummary() {
    Map<String, Object> summary = new Map<String, Object>();
    Decimal healthScore = calculateBasicHealthScore();
    summary.put('overallHealthScore', healthScore);
    summary.put('systemStatus', getSystemStatus(healthScore));
    summary.put('systemUptime', calculateSystemUptime());
    summary.put('averageResponseTime', getAverageResponseTime());
    summary.put('errorRate', getErrorRate());
    return summary;
}

private static List<Map<String, Object>> getComponentHealth() {
    List<Map<String, Object>> components = new List<Map<String, Object>>();
    components.add(createComponentHealth('Document Generation', checkDocGenHealth()));
    components.add(createComponentHealth('E-Signature', checkSignatureHealth()));
    components.add(createComponentHealth('Database', checkDatabaseHealth()));
    components.add(createComponentHealth('API Services', checkApiHealth()));
    return components;
}

private static List<Map<String, Object>> getCriticalAlerts() {
    List<Map<String, Object>> alerts = new List<Map<String, Object>>();
    List<System_Alert__c> criticalAlerts = [
        SELECT Id, Alert_Type__c, Severity__c, Message__c,
               Created_By__c, CreatedDate, Component__c
        FROM System_Alert__c
        WHERE Status__c = 'ACTIVE'
        AND Severity__c IN ('CRITICAL', 'HIGH')
        ORDER BY CreatedDate DESC
        LIMIT 10
    ];
    for (System_Alert__c alert : criticalAlerts) {
        Map<String, Object> alertData = new Map<String, Object>();
        alertData.put('id', alert.Id);
        alertData.put('title', alert.Alert_Type__c);
        alertData.put('message', alert.Message__c);
        alertData.put('severity', alert.Severity__c);
        alertData.put('component', alert.Component__c);
        alertData.put('formattedTime', alert.CreatedDate.format());
        alertData.put('canAcknowledge', true);
        alerts.add(alertData);
    }
    return alerts;
}

private static Map<String, Object> getBasicPerformanceMetrics() {
    Map<String, Object> metrics = new Map<String, Object>();
    List<AggregateResult> perfStats = [
        SELECT AVG(Response_Time_Ms__c) avgTime,
               AVG(Error_Rate__c) avgError,
               COUNT(Id) totalOps
        FROM Performance_Log__c
        WHERE CreatedDate >= :DateTime.now().addHours(-24)
    ];
    if (!perfStats.isEmpty()) {
        AggregateResult stats = perfStats[0];
        metrics.put('averageResponseTime', stats.get('avgTime'));
        metrics.put('errorRate', stats.get('avgError'));
        metrics.put('totalOperations', stats.get('totalOps'));
    }
    return metrics;
}

private static Decimal calculateBasicHealthScore() {
    Decimal score = 100;
    try {
        Decimal avgResponseTime = getAverageResponseTime();
        if (avgResponseTime > 5000) score -= 40;
        else if (avgResponseTime > 3000) score -= 20;
        else if (avgResponseTime > 2000) score -= 10;

        Decimal errorRate = getErrorRate();
        if (errorRate > 5) score -= 30;
        else if (errorRate > 2) score -= 15;
        else if (errorRate > 1) score -= 5;

        Decimal uptime = calculateSystemUptime();
        if (uptime < 95) score -= 30;
        else if (uptime < 98) score -= 15;
        else if (uptime < 99.5) score -= 5;
    } catch (Exception e) {
        score = 50;
    }
    return Math.max(score, 0);
}

private static String getSystemStatus(Decimal healthScore) {
    if (healthScore >= 95) return 'Excellent';
    if (healthScore >= 85) return 'Good';
    if (healthScore >= 70) return 'Fair';
    return 'Needs Attention';
}

private static Decimal calculateSystemUptime() {
    DateTime last24Hours = DateTime.now().addHours(-24);
    Integer totalMinutes = 24 * 60;
    List<System_Alert__c> downtimeAlerts = [
        SELECT Duration_Minutes__c
        FROM System_Alert__c
        WHERE CreatedDate >= :last24Hours
        AND Alert_Type__c = 'SYSTEM_DOWN'
    ];
    Integer downtimeMinutes = 0;
    for (System_Alert__c alert : downtimeAlerts) {
        if (alert.Duration_Minutes__c != null) {
            downtimeMinutes += Integer.valueOf(alert.Duration_Minutes__c);
        }
    }
    return ((totalMinutes - downtimeMinutes) * 100.0) / totalMinutes;
}

private static Decimal getAverageResponseTime() {
    List<AggregateResult> results = [
        SELECT AVG(Response_Time_Ms__c) avgTime
        FROM Performance_Log__c
        WHERE CreatedDate >= :DateTime.now().addHours(-1)
    ];
    return !results.isEmpty() && results[0].get('avgTime') != null
        ? (Decimal)results[0].get('avgTime')
        : 1500;
}

private static Decimal getErrorRate() {
    // Get total operations in the last hour
    Integer total = [
        SELECT COUNT()
        FROM System_Operation_Log__c
        WHERE CreatedDate >= :DateTime.now().addHours(-1)
    ];
    
    // Get total errors in the last hour
    Integer errors = [
        SELECT COUNT()
        FROM System_Operation_Log__c
        WHERE CreatedDate >= :DateTime.now().addHours(-1)
        AND Status__c = 'ERROR'
    ];
    
    // Calculate percentage
    return total > 0 ? (errors * 100.0) / total : 0;
}

private static Map<String, Object> createComponentHealth(String name, Boolean isHealthy) {
    Map<String, Object> component = new Map<String, Object>();
    component.put('componentName', name);
    component.put('status', isHealthy ? 'Healthy' : 'Degraded');
    component.put('healthScore', isHealthy ? 100 : 50);
    component.put('statusVariant', isHealthy ? 'success' : 'warning');
    return component;
}

// Component checks
private static Boolean checkDocGenHealth() {
    try {
        Integer recentErrors = [
            SELECT COUNT()
            FROM System_Operation_Log__c
            WHERE Operation_Type__c = 'DOCUMENT_GENERATION'
            AND Status__c = 'ERROR'
            AND CreatedDate >= :DateTime.now().addHours(-1)
        ];
        return recentErrors < 5;
    } catch (Exception e) {
        return false;
    }
}

private static Boolean checkSignatureHealth() {
    try {
        Integer recentErrors = [
            SELECT COUNT()
            FROM System_Operation_Log__c
            WHERE Operation_Type__c = 'SIGNATURE_REQUEST'
            AND Status__c = 'ERROR'
            AND CreatedDate >= :DateTime.now().addHours(-1)
        ];
        return recentErrors < 3;
    } catch (Exception e) {
        return false;
    }
}

private static Boolean checkDatabaseHealth() {
    try {
        Integer recordCount = [SELECT COUNT() FROM System_Health_Check__c LIMIT 1];
        return true;
    } catch (Exception e) {
        return false;
    }
}

private static Boolean checkApiHealth() {
    try {
        List<AggregateResult> apiStats = [
            SELECT AVG(Response_Time_Ms__c) avgTime
            FROM API_Call_Log__c
            WHERE CreatedDate >= :DateTime.now().addMinutes(-15)
        ];
        if (!apiStats.isEmpty() && apiStats[0].get('avgTime') != null) {
            Decimal avgTime = (Decimal)apiStats[0].get('avgTime');
            return avgTime < 5000;
        }
        return true;
    } catch (Exception e) {
        return false;
    }
}

    
}
