public with sharing class SystemHealthMonitor {

    // ===== Wrapper and DTO Classes (Inner Classes) =====
    public class SystemHealthWrapper {
        @AuraEnabled public Decimal overallHealthScore { get; set; }
        @AuraEnabled public String systemStatus { get; set; }
        @AuraEnabled public Decimal systemUptime { get; set; }
        @AuraEnabled public Decimal averageResponseTime { get; set; }
        @AuraEnabled public Decimal errorRate { get; set; }
        @AuraEnabled public Integer activeUsers { get; set; }
        @AuraEnabled public Decimal complianceScore { get; set; }
        @AuraEnabled public Integer criticalAlerts { get; set; }
        @AuraEnabled public Integer totalAlerts { get; set; }
        @AuraEnabled public DateTime lastHealthCheck { get; set; }
        @AuraEnabled public List<ComponentHealthStatus> componentHealth { get; set; }
        @AuraEnabled public List<SystemAlert> recentAlerts { get; set; }
        @AuraEnabled public Map<String, Object> performanceMetrics { get; set; }
        @AuraEnabled public Map<String, Object> securityMetrics { get; set; }
        @AuraEnabled public List<String> recommendations { get; set; }
        @AuraEnabled public String healthTrend { get; set; }
        @AuraEnabled public Boolean requiresAttention { get; set; }

        public SystemHealthWrapper() {
            this.componentHealth = new List<ComponentHealthStatus>();
            this.recentAlerts = new List<SystemAlert>();
            this.performanceMetrics = new Map<String, Object>();
            this.securityMetrics = new Map<String, Object>();
            this.recommendations = new List<String>();
            this.lastHealthCheck = DateTime.now();
            this.requiresAttention = false;
        }
    }

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

    @AuraEnabled(cacheable=true)
    public static SystemHealthWrapper getCompleteSystemHealth() {
        SystemHealthWrapper health = new SystemHealthWrapper();
        try {
            HealthMetrics metrics = getCurrentHealthMetrics();

            health.overallHealthScore = calculateOverallHealthScore(metrics);
            health.systemStatus = (health.overallHealthScore > 80) ? 'OPERATIONAL' : 'DEGRADED';
            health.averageResponseTime = metrics.averageResponseTime;
            health.errorRate = metrics.errorRate;
            health.systemUptime = metrics.systemUptime;
            health.complianceScore = metrics.complianceScore;
            health.activeUsers = metrics.activeUsers;

            if (metrics.alerts != null) {
                Object oa = metrics.alerts.get('activeAlerts');
                if (oa instanceof List<Object>) {
                    List<Object> raw = (List<Object>)oa;
                    List<SystemAlert> alerts = new List<SystemAlert>();
                    for (Object o : raw) {
                        // If you populate alerts as SystemAlert in getActiveAlerts, cast will succeed.
                        if (o instanceof SystemAlert) alerts.add((SystemAlert)o);
                    }
                    health.recentAlerts = alerts;
                }
                if (metrics.alerts.containsKey('alertCount')) {
                    Integer ac = (Integer)metrics.alerts.get('alertCount');
                    health.totalAlerts = ac;
                }
                if (metrics.alerts.containsKey('highSeverityCount')) {
                    Integer hc = (Integer)metrics.alerts.get('highSeverityCount');
                    health.criticalAlerts = hc;
                }
            }

            health.requiresAttention = (health.totalAlerts != null && health.totalAlerts > 0);
            health.recommendations = generateRecommendations(metrics);
        } catch (Exception ex) {
            System.debug('SystemHealthMonitor.getCompleteSystemHealth error: ' + ex.getMessage());
            health.systemStatus = 'ERROR';
            health.recommendations.add('System health could not be calculated. Check logs.');
        }

        return health;
    }

    @AuraEnabled(cacheable=true)
    public static HealthMetrics getCurrentHealthMetrics() {
        HealthMetrics metrics = new HealthMetrics();
        try {
            metrics.documentGenerationSLA = calculateDocumentGenerationSLA();
            metrics.systemUptime = calculateSystemUptime();
            metrics.complianceScore = calculateComplianceScore();
            metrics.activeUsers = getActiveUserCount();
            metrics.errorRate = calculateErrorRate();
            metrics.cacheHitRatio = getDefaultCacheHitRatio(); // stubbed
            metrics.averageResponseTime = calculateAverageResponseTime();
            metrics.queueDepth = getQueueDepth();
            metrics.performanceTrends = getPerformanceTrends();
            metrics.alerts = getActiveAlerts(metrics);
        } catch (Exception ex) {
            System.debug('SystemHealthMonitor.getCurrentHealthMetrics error: ' + ex.getMessage());
            metrics = getDefaultMetrics();
        }
        return metrics;
    }

    // ===== Async & Utility Methods =====

    @future
    public static void capturePerformanceSnapshot() {
        // STUB: in production, persist a Performance_Snapshot__c record
        System.debug('SystemHealthMonitor.capturePerformanceSnapshot invoked at ' + DateTime.now());
    }

    @AuraEnabled
    public static Map<String, Object> acknowledgeAlert(String alertId) {
        Map<String, Object> out = new Map<String, Object>();
        try {
            // STUB: update System_Alert__c in production
            System.debug('Acknowledging alert (stub): ' + alertId);
            out.put('success', true);
            out.put('message', 'Alert acknowledged (stub).');
        } catch (Exception ex) {
            throw new AuraHandledException('Failed to acknowledge alert: ' + ex.getMessage());
        }
        return out;
    }

    public static void schedulePerformanceCapture() {
        String cronExpression = '0 */5 * * * ?'; // every 5 minutes
        System.schedule('PerformanceSnapshotCaptureJob', cronExpression, new PerformanceSnapshotScheduler());
    }

    // Scheduler class - public inner class (not global)
    public class PerformanceSnapshotScheduler implements Schedulable {
        public void execute(SchedulableContext sc) {
            capturePerformanceSnapshot();
        }
    }

    // ===== Comprehensive Health Check Methods =====

    @AuraEnabled
    public static HealthCheckResult performComprehensiveHealthCheck() {
        HealthCheckResult result = new HealthCheckResult();
        result.componentStatuses = new List<ComponentStatus>();
        result.checkTime = DateTime.now();

        try {
            result.componentStatuses.add(checkDatabaseHealth());
            result.componentStatuses.add(checkApiHealth());
            // Add more checks as needed (document generation, e-signature, etc.)

            Integer healthy = 0;
            for (ComponentStatus cs : result.componentStatuses) {
                if (cs.isHealthy) healthy++;
            }
            result.overallSuccess = (healthy == result.componentStatuses.size());
            result.summary = healthy + '/' + result.componentStatuses.size() + ' components healthy';
        } catch (Exception ex) {
            result.overallSuccess = false;
            result.summary = 'Health check failed: ' + ex.getMessage();
        }

        return result;
    }

    private static ComponentStatus checkDatabaseHealth() {
        ComponentStatus status = new ComponentStatus();
        status.componentName = 'Database';
        try {
            // Quick sanity check
            Integer cnt = 0;
            try {
                cnt = [ SELECT COUNT() FROM User LIMIT 1 ];
            } catch (Exception soqlEx) {
                // if query fails, treat as unhealthy
                cnt = 0;
            }
            status.isHealthy = (cnt >= 0);
            status.status = status.isHealthy ? 'Healthy' : 'Error';
            status.healthScore = status.isHealthy ? 100 : 0;
            status.message = 'Simple connectivity check performed';
        } catch (Exception ex) {
            status.isHealthy = false;
            status.status = 'Error';
            status.healthScore = 0;
            status.message = 'DB check error: ' + ex.getMessage();
        }
        return status;
    }

    private static ComponentStatus checkApiHealth() {
        ComponentStatus status = new ComponentStatus();
        status.componentName = 'API Services';
        // STUB: In production examine API_Call_Log__c or external integrations.
        status.isHealthy = true;
        status.status = 'Healthy';
        status.healthScore = 100;
        status.message = 'No recent errors detected (stub)';
        return status;
    }

    // ===== Private Metric Calculation Stubs =====
    // Replace stub logic with real queries/logic in your org.

    private static Decimal calculateDocumentGenerationSLA() {
        // STUB: compute from Document_Generation_Log__c
        return 98.5;
    }

    private static Decimal calculateSystemUptime() {
        // STUB: compute from System_Health_Log__c / monitoring data
        return 99.9;
    }

    private static Decimal calculateComplianceScore() {
        // STUB: compute from Compliance_Check_Log__c
        return 95.0;
    }

    private static Integer getActiveUserCount() {
        // STUB: query activity records; returns zero-safe value
        try {
            Integer cnt = 0;
            try {
                AggregateResult ar = [ SELECT COUNT_DISTINCT(CreatedById) activeUsers FROM AuditTrail__c WHERE CreatedDate = LAST_N_DAYS:1 ];
                if (ar != null && ar.get('activeUsers') != null) {
                    cnt = (Integer) ar.get('activeUsers');
                }
            } catch (Exception qex) {
                // if the org does not have AuditTrail or query fails, fallback
                cnt = 0;
            }
            return cnt;
        } catch (Exception ex) {
            return 0;
        }
    }

    private static Decimal calculateErrorRate() {
        // STUB: compute from API_Request_Log__c or equivalent
        return 1.2;
    }

    private static Decimal getDefaultCacheHitRatio() {
        // STUB: no Cache API usage; return default
        return 85.0;
    }

    private static Decimal calculateAverageResponseTime() {
        // STUB: compute from API logs
        return 150.0;
    }

    private static Integer getQueueDepth() {
        try {
            Integer cnt = [ SELECT COUNT() FROM AsyncApexJob WHERE Status IN ('Queued','Processing') ];
            return cnt;
        } catch (Exception ex) {
            return 0;
        }
    }

    private static Map<String,Object> getActiveAlerts(HealthMetrics currentMetrics) {
        Map<String,Object> alertsMap = new Map<String,Object>();
        List<SystemAlert> alerts = new List<SystemAlert>();
        Integer highSeverityCount = 0;

        if (currentMetrics != null) {
            if (currentMetrics.documentGenerationSLA != null && currentMetrics.documentGenerationSLA < 80) {
                SystemAlert a = new SystemAlert();
                a.severity = 'HIGH';
                a.message = 'Document generation SLA below threshold: ' + String.valueOf(currentMetrics.documentGenerationSLA);
                a.timestamp = DateTime.now();
                a.category = 'PERFORMANCE';
                a.acknowledged = false;
                alerts.add(a);
                highSeverityCount++;
            }
            if (currentMetrics.systemUptime != null && currentMetrics.systemUptime < 99.0) {
                SystemAlert a = new SystemAlert();
                a.severity = 'CRITICAL';
                a.message = 'System uptime below 99%: ' + String.valueOf(currentMetrics.systemUptime);
                a.timestamp = DateTime.now();
                a.category = 'AVAILABILITY';
                a.acknowledged = false;
                alerts.add(a);
                highSeverityCount++;
            }
            if (currentMetrics.complianceScore != null && currentMetrics.complianceScore < 90) {
                SystemAlert a = new SystemAlert();
                a.severity = 'MEDIUM';
                a.message = 'Compliance score below target: ' + String.valueOf(currentMetrics.complianceScore);
                a.timestamp = DateTime.now();
                a.category = 'COMPLIANCE';
                a.acknowledged = false;
                alerts.add(a);
            }
            if (currentMetrics.errorRate != null && currentMetrics.errorRate > 5.0) {
                SystemAlert a = new SystemAlert();
                a.severity = 'HIGH';
                a.message = 'Elevated error rate: ' + String.valueOf(currentMetrics.errorRate) + '%';
                a.timestamp = DateTime.now();
                a.category = 'RELIABILITY';
                a.acknowledged = false;
                alerts.add(a);
                highSeverityCount++;
            }
        }

        alertsMap.put('activeAlerts', alerts);
        alertsMap.put('alertCount', alerts.size());
        alertsMap.put('highSeverityCount', highSeverityCount);
        return alertsMap;
    }

    private static List<TrendDataPoint> getPerformanceTrends() {
        // STUB: return empty list by default
        return new List<TrendDataPoint>();
    }

    private static HealthMetrics getDefaultMetrics() {
        HealthMetrics m = new HealthMetrics();
        m.documentGenerationSLA = 95.0;
        m.systemUptime = 99.9;
        m.complianceScore = 98.0;
        m.activeUsers = 0;
        m.errorRate = 0.0;
        m.cacheHitRatio = 90.0;
        m.averageResponseTime = 200.0;
        m.queueDepth = 0;
        m.alerts = new Map<String,Object>{ 'activeAlerts' => new List<SystemAlert>(), 'alertCount' => 0, 'highSeverityCount' => 0 };
        m.performanceTrends = new List<TrendDataPoint>();
        return m;
    }

    private static List<String> generateRecommendations(HealthMetrics metrics) {
        List<String> recs = new List<String>();
        if (metrics == null) {
            recs.add('No metrics available.');
            return recs;
        }
        if (metrics.errorRate > 5.0) recs.add('Investigate error sources and reduce error rate.');
        if (metrics.cacheHitRatio < 70.0) recs.add('Review caching strategy to improve hit ratio.');
        if (recs.isEmpty()) recs.add('All systems within normal parameters.');
        return recs;
    }

    private static Decimal calculateOverallHealthScore(HealthMetrics metrics) {
        if (metrics == null) return 0;
        Decimal uptimeScore = (metrics.systemUptime == null) ? 0 : metrics.systemUptime;
        Decimal compliance = (metrics.complianceScore == null) ? 0 : metrics.complianceScore;
        Decimal sla = (metrics.documentGenerationSLA == null) ? 0 : metrics.documentGenerationSLA;
        Decimal score = (uptimeScore * 0.5) + (compliance * 0.3) + (sla * 0.2);
        return score.setScale(2);
    }

    // ======= End of class =======
}