public class SystemHealthScheduler implements Schedulable {
    
    public void execute(SchedulableContext context) {
        try {
            System.debug('=== EXECUTING SCHEDULED SYSTEM HEALTH CHECK ===');
            
            // Perform comprehensive health check
            SystemHealthMonitor.SystemHealthWrapper currentHealth = SystemHealthMonitor.getCompleteSystemHealth();
            
            // Create health snapshot
            SystemHealthMonitor.createHealthSnapshot(currentHealth);
            
            // Check for critical issues
            if (currentHealth.overallHealthScore < 60) {
                // Trigger automated recovery
                SystemRecoveryManager.initiateRecovery();
            }
            
            // Check for performance degradation
            if (currentHealth.averageResponseTime > 5000) {
                // Trigger performance optimization
                PerformanceOptimizer.emergencyOptimization();
            }
            
            // Check for high error rates
            if (currentHealth.errorRate > 10) {
                // Trigger error investigation
                triggerErrorInvestigation();
            }
            
            // Update system metrics
            updateScheduledMetrics(currentHealth);
            
            // Clean up old data
            performScheduledCleanup();
            
            System.debug('✓ Scheduled system health check completed successfully');
            
        } catch (Exception e) {
            System.debug('✗ Scheduled health check failed: ' + e.getMessage());
            createSystemAlert(
                'SCHEDULED_HEALTH_CHECK_FAILED',
                'HIGH',
                'Scheduled system health check encountered an error: ' + e.getMessage()
            );
        }
    }
    
    
    // === ERROR INVESTIGATION ===
    private static void triggerErrorInvestigation() {
        try {
            Error_Investigation__c investigation = new Error_Investigation__c(
                Investigation_Date__c = DateTime.now(),
                Trigger_Reason__c = 'High error rate detected during scheduled check',
                Status__c = 'ACTIVE',
                Assigned_To__c = UserInfo.getUserId(),
                Priority__c = 'HIGH'
            );
            insert investigation;
            
            // Analyze recent errors
            analyzeRecentErrors();
            
        } catch (Exception e) {
            System.debug('Error investigation trigger failed: ' + e.getMessage());
        }
    }
    
    private static void analyzeRecentErrors() {
        try {
            DateTime last4Hours = DateTime.now().addHours(-4);
            
            List<AggregateResult> errorAnalysis = [
                SELECT Status__c, COUNT(Id) errorCount
                FROM AuditTrail__c
                WHERE Timestamp__c >= :last4Hours
                AND Status__c = 'ERROR'
                GROUP BY Status__c
            ];
            
            for (AggregateResult analysis : errorAnalysis) {
                Error_Analysis__c errorRecord = new Error_Analysis__c(
                    Analysis_Date__c = Date.today(),
                    Error_Type__c = (String)analysis.get('Status__c'),
                    Error_Count__c = (Integer)analysis.get('errorCount'),
                    Analysis_Period__c = '4_HOURS',
                    Analyzed_By__c = UserInfo.getUserId()
                );
                insert errorRecord;
            }
            
        } catch (Exception e) {
            System.debug('Error analysis failed: ' + e.getMessage());
        }
    }
    
    
    // === METRICS UPDATE ===
    private static void updateScheduledMetrics(SystemHealthMonitor.SystemHealthWrapper health) {
        try {
            Scheduled_Metrics__c metrics = new Scheduled_Metrics__c(
                Metric_Date__c = Date.today(),
                Health_Score__c = health.overallHealthScore,
                Response_Time__c = health.averageResponseTime,
                Error_Rate__c = health.errorRate,
                Uptime__c = health.systemUptime,
                Active_Alerts__c = health.totalAlerts,
                Compliance_Score__c = health.complianceScore,
                Recorded_At__c = DateTime.now()
            );
            insert metrics;
            
        } catch (Exception e) {
            System.debug('Scheduled metrics update failed: ' + e.getMessage());
        }
    }
    
    
    // === CLEANUP ===
    private static void performScheduledCleanup() {
        try {
            // Clean up old performance snapshots
            DateTime cleanupDate = DateTime.now().addDays(-30);
            List<Performance_Snapshot__c> oldSnapshots = [
                SELECT Id
                FROM Performance_Snapshot__c
                WHERE Snapshot_Time__c < :cleanupDate
                LIMIT 1000
            ];
            
            if (!oldSnapshots.isEmpty()) {
                delete oldSnapshots;
                System.debug('✓ Cleaned up ' + oldSnapshots.size() + ' old performance snapshots');
            }
            
            // Clean up resolved alerts older than 7 days
            DateTime alertCleanupDate = DateTime.now().addDays(-7);
            List<System_Alert__c> oldAlerts = [
                SELECT Id
                FROM System_Alert__c
                WHERE Status__c IN ('RESOLVED', 'DISMISSED')
                AND Resolved_At__c < :alertCleanupDate
                LIMIT 500
            ];
            
            if (!oldAlerts.isEmpty()) {
                delete oldAlerts;
                System.debug('✓ Cleaned up ' + oldAlerts.size() + ' old alerts');
            }
            
        } catch (Exception e) {
            System.debug('Scheduled cleanup failed: ' + e.getMessage());
        }
    }
    
    
    // === JOB SCHEDULER ===
    public static void scheduleHealthMonitoring() {
        try {
            // Check if job is already scheduled
            List<CronTrigger> existingJobs = [
                SELECT Id
                FROM CronTrigger
                WHERE CronJobDetail.Name = 'SystemHealthScheduler'
                AND State = 'WAITING'
            ];
            
            if (existingJobs.isEmpty()) {
                // Schedule job to run every 15 minutes
                String cronExpression = '0 */15 * * * ?';
                System.schedule('SystemHealthScheduler', cronExpression, new SystemHealthScheduler());
                System.debug('✓ System health monitoring scheduled');
            } else {
                System.debug('System health monitoring already scheduled');
            }
            
        } catch (Exception e) {
            System.debug('Health monitoring scheduling failed: ' + e.getMessage());
        }
    }
}
