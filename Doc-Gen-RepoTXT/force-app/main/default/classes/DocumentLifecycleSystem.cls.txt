 public with sharing class DocumentLifecycleSystem {

    public static String getSystemStatus() {
        Map<String, Object> systemStatus = new Map<String, Object>();

        try {
            // Check system components
            systemStatus.put('configurations_count',
                [SELECT COUNT() FROM DocumentLifecycleConfiguration__c]);

            systemStatus.put('retention_policies_count',
                [SELECT COUNT() FROM DocumentRetentionPolicy__c WHERE Is_Active__c = true]);

            systemStatus.put('active_monitoring_count',
                [SELECT COUNT() FROM DocumentRealTimeMonitoring__c WHERE Monitoring_Enabled__c = true]);

            systemStatus.put('documents_under_management',
                [SELECT COUNT() FROM DocumentLifecycleTracking__c WHERE Status__c = 'ACTIVE']);

            systemStatus.put('compliance_violations_active',
                [SELECT COUNT() FROM DocumentComplianceFinding__c 
                 WHERE Status__c = 'OPEN' AND Severity__c IN ('HIGH', 'CRITICAL')]);

            systemStatus.put('pending_expirations_30_days',
                [SELECT COUNT() FROM DocumentExpirationTracking__c 
                 WHERE Days_Until_Expiration__c <= 30 AND Days_Until_Expiration__c > 0]);

            // Calculate system health score
            Decimal healthScore = calculateSystemHealthScore();
            systemStatus.put('system_health_score', healthScore);
            systemStatus.put('system_health_status', getHealthStatus(healthScore));
            systemStatus.put('last_monitoring_run', getLastMonitoringRunTime());
            systemStatus.put('system_uptime_hours', getSystemUptimeHours());

            // Check critical system alerts
            Integer criticalAlerts = [
                SELECT COUNT() FROM SystemAlert__c 
                WHERE Priority__c = 'CRITICAL' AND Status__c = 'ACTIVE'
            ];

            systemStatus.put('critical_alerts_count', criticalAlerts);
            systemStatus.put('system_operational', criticalAlerts == 0);
            systemStatus.put('status_timestamp', DateTime.now());

            return JSON.serialize(systemStatus, true);

        } catch (Exception e) {
            systemStatus.put('status_error', e.getMessage());
            systemStatus.put('system_operational', false);
            return JSON.serialize(systemStatus, true);
        }
    }

    // =======================
    // Health Calculation
    // =======================
    private static Decimal calculateSystemHealthScore() {
        Decimal baseScore = 100.0;

        try {
            // Deduct points for active violations
            Integer violations = [
                SELECT COUNT() FROM DocumentComplianceFinding__c 
                WHERE Status__c = 'OPEN' AND Severity__c IN ('HIGH', 'CRITICAL')
            ];
            baseScore -= (violations * 5); // 5 points per violation

            // Deduct points for overdue documents
            Integer overdueCount = [
                SELECT COUNT() FROM DocumentExpirationTracking__c 
                WHERE Days_Until_Expiration__c < 0
            ];
            baseScore -= (overdueCount * 3); // 3 points per overdue doc

            // Deduct points for system errors
            Integer systemErrors = [
                SELECT COUNT() FROM SystemAlert__c 
                WHERE Priority__c IN ('HIGH', 'CRITICAL') 
                AND Status__c = 'ACTIVE'
                AND CreatedDate >= :DateTime.now().addDays(-1)
            ];
            baseScore -= (systemErrors * 10); // 10 points per error

            // Ensure score doesn't drop below 0
            return Math.max(0, baseScore);

        } catch (Exception e) {
            return 0; // Return 0 if health calculation fails
        }
    }

    private static String getHealthStatus(Decimal healthScore) {
        if (healthScore >= 95) return 'EXCELLENT';
        if (healthScore >= 85) return 'GOOD';
        if (healthScore >= 70) return 'FAIR';
        if (healthScore >= 50) return 'POOR';
        return 'CRITICAL';
    }

    private static DateTime getLastMonitoringRunTime() {
        try {
            SystemAlert__c lastAlert = [
                SELECT CreatedDate 
                FROM SystemAlert__c 
                WHERE Alert_Type__c = 'MONITORING_COMPLETED' 
                ORDER BY CreatedDate DESC LIMIT 1
            ];
            return lastAlert != null ? lastAlert.CreatedDate : null;
        } catch (Exception e) {
            return null;
        }
    }

    private static Decimal getSystemUptimeHours() {
        try {
            SystemInitializationLog__c lastInit = [
                SELECT Initialization_Date__c 
                FROM SystemInitializationLog__c 
                WHERE Component_Name__c = 'Document Lifecycle Management' 
                AND Initialization_Status__c = 'SUCCESS' 
                ORDER BY Initialization_Date__c DESC LIMIT 1
            ];

            if (lastInit != null) {
                Long diffMillis = DateTime.now().getTime() - lastInit.Initialization_Date__c.getTime();
                return diffMillis / (1000 * 60 * 60); // Convert ms → hours
            }
            return 0;
        } catch (Exception e) {
            return 0;
        }
    }
}
