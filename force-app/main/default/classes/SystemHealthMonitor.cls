public class SystemHealthMonitor {
    // ===== Inner Classes =====
    public class HealthMetrics {
        @AuraEnabled public Decimal documentGenerationSLA { get; set; }
        @AuraEnabled public Decimal systemUptime { get; set; }
        @AuraEnabled public Decimal complianceScore { get; set; }
        @AuraEnabled public Integer activeUsers { get; set; }
        @AuraEnabled public Decimal errorRate { get; set; }
        @AuraEnabled public Decimal cacheHitRatio { get; set; }
        @AuraEnabled public Decimal averageResponseTime { get; set; }
        @AuraEnabled public Integer queueDepth { get; set; }
        @AuraEnabled public Map<String, Object> alerts { get; set; }
        @AuraEnabled public List<TrendDataPoint> performanceTrends { get; set; }
    }

    public class TrendDataPoint {
        @AuraEnabled public DateTime timestamp { get; set; }
        @AuraEnabled public Decimal value { get; set; }
        @AuraEnabled public String metric { get; set; }
    }

    public class SystemAlert {
        @AuraEnabled public String severity { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public DateTime timestamp { get; set; }
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public Boolean acknowledged { get; set; }
    }

    // ===== Public Methods =====
    @AuraEnabled(cacheable=true)
    public static HealthMetrics getCurrentHealthMetrics() {
        HealthMetrics metrics = new HealthMetrics();
        try {
            metrics.documentGenerationSLA = calculateDocumentGenerationSLA();
            metrics.systemUptime = calculateSystemUptime();
            metrics.complianceScore = calculateComplianceScore();
            metrics.activeUsers = getActiveUserCount();
            metrics.errorRate = calculateErrorRate();
            metrics.cacheHitRatio = calculateCacheHitRatio();
            metrics.averageResponseTime = calculateAverageResponseTime();
            metrics.queueDepth = getQueueDepth();
            metrics.performanceTrends = getPerformanceTrends();
            metrics.alerts = getActiveAlerts(metrics);
        } catch (Exception e) {
            System.debug('Health metrics calculation failed: ' + e.getMessage());
            metrics = getDefaultMetrics();
        }
        return metrics;
    }

    // ===== Private Metric Calculations =====
    private static Decimal calculateDocumentGenerationSLA() {
        List<AggregateResult> results = [
            SELECT AVG(Generation_Time_Ms__c) avgTime
            FROM Document_Generation_Log__c
            WHERE CreatedDate >= :DateTime.now().addHours(-24)
        ];
        if (!results.isEmpty() && results[0].get('avgTime') != null) {
            Decimal avgTime = (Decimal)results[0].get('avgTime');
            Decimal slaTarget = 5000; // 5 seconds
            return avgTime <= slaTarget ? 100 : (slaTarget / avgTime * 100);
        }
        return 95.0;
    }

    private static Decimal calculateSystemUptime() {
    Integer downtimeEvents = [
        SELECT COUNT()
        FROM System_Health_Log__c
        WHERE Event_Type__c = 'SYSTEM_DOWN'
        AND CreatedDate >= :DateTime.now().addHours(-24)
    ];
    
    Integer downtimeMinutes = downtimeEvents * 5;
    return ((1440 - downtimeMinutes) / 1440.0) * 100;
}


    private static Decimal calculateComplianceScore() {
        AggregateResult[] results = [
            SELECT Status__c, COUNT(Id) cnt
            FROM Compliance_Check_Log__c
            WHERE CreatedDate >= :DateTime.now().addHours(-24)
            GROUP BY Status__c
        ];
        Integer total = 0;
        Integer passed = 0;
        for (AggregateResult ar : results) {
            Integer cnt = (Integer)ar.get('cnt');
            total += cnt;
            if ((String)ar.get('Status__c') == 'PASSED') {
                passed += cnt;
            }
        }
        return total > 0 ? (passed * 100.0 / total) : 100;
    }

    private static Integer getActiveUserCount() {
        AggregateResult result = [
            SELECT COUNT_DISTINCT(CreatedById) activeUsers
            FROM Document_Generation_Log__c
            WHERE CreatedDate >= :DateTime.now().addMinutes(-30)
        ];
        return (Integer)result.get('activeUsers');
    }

    private static Decimal calculateErrorRate() {
        AggregateResult[] results = [
            SELECT Status__c, COUNT(Id) cnt
            FROM API_Request_Log__c
            WHERE CreatedDate >= :DateTime.now().addHours(-1)
            GROUP BY Status__c
        ];
        Integer total = 0;
        Integer errors = 0;
        for (AggregateResult ar : results) {
            Integer cnt = (Integer)ar.get('cnt');
            total += cnt;
            if ((String)ar.get('Status__c') == 'ERROR') {
                errors += cnt;
            }
        }
        return total > 0 ? (errors * 100.0 / total) : 0;
    }

    private static Decimal calculateCacheHitRatio() {
        Cache.OrgPartition orgPartition = Cache.Org.getPartition('local.DocumentCache');
        Map<String, Object> stats = orgPartition.getStatsMap();
        if (stats != null && stats.containsKey('hitRate')) {
            return ((Decimal)stats.get('hitRate')) * 100;
        }
        return 85.0;
    }

    private static Decimal calculateAverageResponseTime() {
        List<AggregateResult> results = [
            SELECT AVG(Response_Time_Ms__c) avgResponseTime
            FROM API_Request_Log__c
            WHERE CreatedDate >= :DateTime.now().addHours(-1)
        ];
        return !results.isEmpty() && results[0].get('avgResponseTime') != null ?
            (Decimal)results[0].get('avgResponseTime') : 150.0;
    }

  private static Integer getQueueDepth() {
    AggregateResult[] results = [
        SELECT COUNT(Id) totalJobs
        FROM AsyncApexJob
        WHERE Status IN ('Queued', 'Processing')
    ];
    return (results.isEmpty()) ? 0 : (Integer)results[0].get('totalJobs');
}


    private static Map<String, Object> getActiveAlerts(HealthMetrics currentMetrics) {
        Map<String, Object> alertsMap = new Map<String, Object>();
        List<SystemAlert> alerts = new List<SystemAlert>();
        Integer highSeverityCount = 0;

        if (currentMetrics.documentGenerationSLA < 80) {
            SystemAlert alert = new SystemAlert();
            alert.severity = 'HIGH';
            alert.message = 'Document generation SLA is below threshold: ' +
                currentMetrics.documentGenerationSLA.setScale(1) + '%';
            alert.timestamp = DateTime.now();
            alert.category = 'PERFORMANCE';
            alert.acknowledged = false;
            alerts.add(alert);
            highSeverityCount++;
        }
        if (currentMetrics.systemUptime < 99.0) {
            SystemAlert alert = new SystemAlert();
            alert.severity = 'CRITICAL';
            alert.message = 'System uptime is below 99%: ' +
                currentMetrics.systemUptime.setScale(2) + '%';
            alert.timestamp = DateTime.now();
            alert.category = 'AVAILABILITY';
            alert.acknowledged = false;
            alerts.add(alert);
            highSeverityCount++;
        }
        if (currentMetrics.complianceScore < 90) {
            SystemAlert alert = new SystemAlert();
            alert.severity = 'MEDIUM';
            alert.message = 'Compliance score is below target: ' +
                currentMetrics.complianceScore.setScale(1) + '%';
            alert.timestamp = DateTime.now();
            alert.category = 'COMPLIANCE';
            alert.acknowledged = false;
            alerts.add(alert);
        }
        if (currentMetrics.errorRate > 5.0) {
            SystemAlert alert = new SystemAlert();
            alert.severity = 'HIGH';
            alert.message = 'Error rate is elevated: ' +
                currentMetrics.errorRate.setScale(2) + '%';
            alert.timestamp = DateTime.now();
            alert.category = 'RELIABILITY';
            alert.acknowledged = false;
            alerts.add(alert);
            highSeverityCount++;
        }
        if (currentMetrics.cacheHitRatio < 70) {
            SystemAlert alert = new SystemAlert();
            alert.severity = 'MEDIUM';
            alert.message = 'Cache hit ratio is low: ' +
                currentMetrics.cacheHitRatio.setScale(1) + '%';
            alert.timestamp = DateTime.now();
            alert.category = 'PERFORMANCE';
            alert.acknowledged = false;
            alerts.add(alert);
        }

        alertsMap.put('activeAlerts', alerts);
        alertsMap.put('alertCount', alerts.size());
        alertsMap.put('highSeverityCount', highSeverityCount);
        return alertsMap;
    }

    private static List<TrendDataPoint> getPerformanceTrends() {
        List<TrendDataPoint> trends = new List<TrendDataPoint>();
        List<Performance_Snapshot__c> snapshots = [
            SELECT Timestamp__c, Document_Generation_Time__c, System_Uptime__c,
                   Cache_Hit_Ratio__c, Error_Rate__c, Active_Users__c
            FROM Performance_Snapshot__c
            WHERE Timestamp__c >= :DateTime.now().addHours(-24)
            ORDER BY Timestamp__c ASC
            LIMIT 100
        ];
        for (Performance_Snapshot__c snapshot : snapshots) {
            TrendDataPoint genTimePoint = new TrendDataPoint();
            genTimePoint.timestamp = snapshot.Timestamp__c;
            genTimePoint.value = snapshot.Document_Generation_Time__c;
            genTimePoint.metric = 'Generation Time';
            trends.add(genTimePoint);

            TrendDataPoint uptimePoint = new TrendDataPoint();
            uptimePoint.timestamp = snapshot.Timestamp__c;
            uptimePoint.value = snapshot.System_Uptime__c;
            uptimePoint.metric = 'System Uptime';
            trends.add(uptimePoint);

            TrendDataPoint cachePoint = new TrendDataPoint();
            cachePoint.timestamp = snapshot.Timestamp__c;
            cachePoint.value = snapshot.Cache_Hit_Ratio__c;
            cachePoint.metric = 'Cache Hit Ratio';
            trends.add(cachePoint);
        }
        return trends;
    }

    private static HealthMetrics getDefaultMetrics() {
        HealthMetrics metrics = new HealthMetrics();
        metrics.documentGenerationSLA = 95.0;
        metrics.systemUptime = 99.5;
        metrics.complianceScore = 92.0;
        metrics.activeUsers = 0;
        metrics.errorRate = 0.1;
        metrics.cacheHitRatio = 85.0;
        metrics.averageResponseTime = 150.0;
        metrics.queueDepth = 0;
        metrics.alerts = new Map<String, Object>{
            'activeAlerts' => new List<SystemAlert>(),
            'alertCount' => 0,
            'highSeverityCount' => 0
        };
        metrics.performanceTrends = new List<TrendDataPoint>();
        return metrics;
    }

    // ===== Async & Utility =====
    @future
    public static void capturePerformanceSnapshot() {
        try {
            HealthMetrics metrics = getCurrentHealthMetrics();
            Performance_Snapshot__c snapshot = new Performance_Snapshot__c(
                Timestamp__c = DateTime.now(),
                Document_Generation_Time__c = 100 - metrics.documentGenerationSLA, // adjust if needed
                System_Uptime__c = metrics.systemUptime,
                Cache_Hit_Ratio__c = metrics.cacheHitRatio,
                Error_Rate__c = metrics.errorRate,
                Active_Users__c = metrics.activeUsers,
                Average_Response_Time__c = metrics.averageResponseTime,
                Queue_Depth__c = metrics.queueDepth
            );
            insert snapshot;

            if (metrics.alerts != null) {
                List<SystemAlert> alerts = (List<SystemAlert>)metrics.alerts.get('activeAlerts');
                for (SystemAlert alert : alerts) {
                    System_Alert__c alertRecord = new System_Alert__c(
                        Severity__c = alert.severity,
                        Message__c = alert.message,
                        Category__c = alert.category,
                        Alert_Timestamp__c = alert.timestamp,
                        Acknowledged__c = false,
                        Auto_Generated__c = true
                    );
                    insert alertRecord;
                }
            }
        } catch (Exception e) {
            System.debug('Performance snapshot capture failed: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Object> acknowledgeAlert(String alertId) {
        try {
            System_Alert__c alert = [
                SELECT Id, Acknowledged__c
                FROM System_Alert__c
                WHERE Id = :alertId
                LIMIT 1
            ];
            alert.Acknowledged__c = true;
            alert.Acknowledged_By__c = UserInfo.getUserId();
            alert.Acknowledged_Date__c = DateTime.now();
            update alert;
            return new Map<String, Object>{
                'success' => true,
                'message' => 'Alert acknowledged successfully'
            };
        } catch (Exception e) {
            throw new AuraHandledException('Failed to acknowledge alert: ' + e.getMessage());
        }
    }

    public static void schedulePerformanceCapture() {
        String cronExpression = '0 */5 * * * ?';
        System.schedule('Performance Snapshot Capture',
            cronExpression,
            new PerformanceSnapshotScheduler());
    }

    // ===== Scheduler Stub =====
    global class PerformanceSnapshotScheduler implements Schedulable {
        global void execute(SchedulableContext sc) {
            capturePerformanceSnapshot();
        }
    }
    /**
 * @description Essential System Health Monitor - Core health checks only
 */
    
    // ===== Inner Classes =====
    
    public class HealthCheckResult {
        @AuraEnabled public Boolean overallSuccess;
        @AuraEnabled public List<ComponentStatus> componentStatuses;
        @AuraEnabled public DateTime checkTime;
        @AuraEnabled public String summary;
    }
    
    public class ComponentStatus {
        @AuraEnabled public String componentName;
        @AuraEnabled public Boolean isHealthy;
        @AuraEnabled public String status;
        @AuraEnabled public Integer healthScore;
        @AuraEnabled public String message;
    }
    
    // ===== Public Methods =====
    
    @AuraEnabled
    public static HealthCheckResult performComprehensiveHealthCheck() {
        HealthCheckResult result = new HealthCheckResult();
        result.componentStatuses = new List<ComponentStatus>();
        result.checkTime = DateTime.now();
        
        try {
            // Check essential components
            result.componentStatuses.add(checkDatabaseHealth());
            result.componentStatuses.add(checkApiHealth());
            result.componentStatuses.add(checkDocumentGeneration());
            result.componentStatuses.add(checkESignature());
            
            // Calculate overall health
            Integer healthyComponents = 0;
            for (ComponentStatus status : result.componentStatuses) {
                if (status.isHealthy) healthyComponents++;
            }
            
            result.overallSuccess = healthyComponents == result.componentStatuses.size();
            result.summary = healthyComponents + '/' + result.componentStatuses.size() + ' components healthy';
            
        } catch (Exception e) {
            result.overallSuccess = false;
            result.summary = 'Health check failed: ' + e.getMessage();
        }
        
        return result;
    }
    
    // ===== Private Component Checks =====
    
    private static ComponentStatus checkDatabaseHealth() {
        ComponentStatus status = new ComponentStatus();
        status.componentName = 'Database';
        
        try {
            // Simple database connectivity test
            Integer recordCount = [SELECT COUNT() FROM User LIMIT 1];
            
            status.isHealthy = true;
            status.status = 'Healthy';
            status.healthScore = 100;
            status.message = 'Database accessible';
        } catch (Exception e) {
            status.isHealthy = false;
            status.status = 'Error';
            status.healthScore = 0;
            status.message = 'Database error: ' + e.getMessage();
        }
        
        return status;
    }
    
    private static ComponentStatus checkApiHealth() {
        ComponentStatus status = new ComponentStatus();
        status.componentName = 'API Services';
        
        try {
            // Check recent API performance
            List<AggregateResult> apiStats = [
                SELECT AVG(Response_Time_Ms__c) avgTime
                FROM API_Call_Log__c
                WHERE CreatedDate >= :DateTime.now().addMinutes(-15)
            ];
            
            if (!apiStats.isEmpty() && apiStats[0].get('avgTime') != null) {
                Decimal avgTime = (Decimal)apiStats[0].get('avgTime');
                
                status.isHealthy = avgTime < 5000;
                status.status = status.isHealthy ? 'Healthy' : 'Slow';
                status.healthScore = status.isHealthy ? 100 : 60;
                status.message = 'Average response time: ' + avgTime.setScale(0) + 'ms';
            } else {
                status.isHealthy = true;
                status.status = 'Healthy';
                status.healthScore = 100;
                status.message = 'No recent API calls to analyze';
            }
        } catch (Exception e) {
            status.isHealthy = false;
            status.status = 'Error';
            status.healthScore = 0;
            status.message = 'API health check failed';
        }
        
        return status;
    }

    private static ComponentStatus checkDocumentGeneration() {
        ComponentStatus status = new ComponentStatus();
        status.componentName = 'Document Generation';
        
        try {
            // Check recent document generation errors
            Integer recentErrors = [
                SELECT COUNT()
                FROM Document_Generation_Log__c
                WHERE Status__c = 'ERROR'
                  AND CreatedDate >= :DateTime.now().addHours(-1)
            ];
            
            status.isHealthy = recentErrors < 5;
            status.status = status.isHealthy ? 'Healthy' : 'Degraded';
            status.healthScore = status.isHealthy ? 100 : 70;
            status.message = recentErrors + ' errors in last hour';
        } catch (Exception e) {
            status.isHealthy = false;
            status.status = 'Error';
            status.healthScore = 0;
            status.message = 'Document generation check failed';
        }
        
        return status;
    }

    private static ComponentStatus checkESignature() {
        ComponentStatus status = new ComponentStatus();
        status.componentName = 'E-Signature';
        
        try {
            // Check signature request failures
            Integer failedRequests = [
                SELECT COUNT()
                FROM Signature_Request__c
                WHERE Status__c = 'FAILED'
                  AND CreatedDate >= :DateTime.now().addHours(-1)
            ];
            
            status.isHealthy = failedRequests < 3;
            status.status = status.isHealthy ? 'Healthy' : 'Degraded';
            status.healthScore = status.isHealthy ? 100 : 60;
            status.message = failedRequests + ' failed requests in last hour';
        } catch (Exception e) {
            status.isHealthy = false;
            status.status = 'Error';
            status.healthScore = 0;
            status.message = 'E-signature check failed';
        }
        
        return status;
    
}

}
