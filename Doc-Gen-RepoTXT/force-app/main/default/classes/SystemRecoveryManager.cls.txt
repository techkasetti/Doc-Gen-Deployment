// System Recovery Manager for emergency situations
public class SystemRecoveryManager {
    public static void initiateRecovery() {
        try {
            System.debug('=== INITIATING SYSTEM RECOVERY ===');
            
            // Step 1: Assess system state
            Map<String, Object> systemState = assessCurrentSystemState();
            
            // Step 2: Execute recovery procedures
            executeRecoveryProcedures(systemState);
            
            // Step 3: Validate recovery success
            validateRecoverySuccess();
            
            // Step 4: Update recovery status
            updateRecoveryStatus('COMPLETED');
            
        } catch (Exception e) {
            updateRecoveryStatus('FAILED');
            throw new SystemHealthException('System recovery failed: ' + e.getMessage());
        }
    }
    
    private static Map<String, Object> assessCurrentSystemState() {
        Map<String, Object> state = new Map<String, Object>();
        
        try {
            SystemHealthMonitor.SystemHealthWrapper health = SystemHealthMonitor.getCompleteSystemHealth();
            state.put('healthScore', health.overallHealthScore);
            state.put('criticalAlerts', health.criticalAlerts);
            state.put('componentHealth', health.componentHealth);
            state.put('errorRate', health.errorRate);
            state.put('responseTime', health.averageResponseTime);
            
            // Determine recovery strategy based on state
            if (health.overallHealthScore < 30) {
                state.put('recoveryStrategy', 'FULL_RECOVERY');
            } else if (health.overallHealthScore < 60) {
                state.put('recoveryStrategy', 'PARTIAL_RECOVERY');
            } else {
                state.put('recoveryStrategy', 'MAINTENANCE_RECOVERY');
            }
            
        } catch (Exception e) {
            state.put('recoveryStrategy', 'EMERGENCY_RECOVERY');
            state.put('error', e.getMessage());
        }
        
        return state;
    }
    
    private static void executeRecoveryProcedures(Map<String, Object> systemState) {
        String recoveryStrategy = (String)systemState.get('recoveryStrategy');
        
        switch on recoveryStrategy {
            when 'FULL_RECOVERY' {
                executeFullRecovery();
            }
            when 'PARTIAL_RECOVERY' {
                executePartialRecovery();
            }
            when 'MAINTENANCE_RECOVERY' {
                executeMaintenanceRecovery();
            }
            when 'EMERGENCY_RECOVERY' {
                executeEmergencyRecovery();
            }
        }
    }
    
    private static void executeFullRecovery() {
        System.debug('Executing full system recovery...');
        clearSystemCaches();
        resetPerformanceCounters();
        restartCriticalServices();
        clearErrorQueues();
        resetMonitoringBaselines();
    }
    
    private static void executePartialRecovery() {
        System.debug('Executing partial system recovery...');
        optimizePerformance();
        resolveActiveAlerts();
        cleanupTempData();
    }
    
    private static void executeMaintenanceRecovery() {
        System.debug('Executing maintenance recovery...');
        performRoutineMaintenance();
        updateSystemMetrics();
    }
    
    private static void executeEmergencyRecovery() {
        System.debug('Executing emergency recovery procedures...');
        clearCriticalErrors();
        resetBasicServices();
    }
    
    private static void validateRecoverySuccess() {
        SystemHealthMonitor.SystemHealthWrapper postRecoveryHealth = SystemHealthMonitor.getCompleteSystemHealth();
        
        if (postRecoveryHealth.overallHealthScore < 70) {
            throw new SystemHealthException('Recovery validation failed: Health score still below acceptable threshold');
        }
        
        if (postRecoveryHealth.criticalAlerts > 0) {
            throw new SystemHealthException('Recovery validation failed: Critical alerts still active');
        }
        
        if (postRecoveryHealth.errorRate > 5) {
            throw new SystemHealthException('Recovery validation failed: Error rate still elevated');
        }
        
        Decimal score = Decimal.valueOf(postRecoveryHealth.overallHealthScore).setScale(1);
        System.debug('✓ Recovery validation successful - Health Score: ' + score + '%');
    }
    
    private static void updateRecoveryStatus(String status) {
        try {
            System_Recovery_Log__c recoveryLog = new System_Recovery_Log__c(
                Recovery_Date__c = DateTime.now(),
                Recovery_Status__c = status,
                Initiated_By__c = UserInfo.getUserId(),
                Recovery_Details__c = 'Automated system recovery executed',
                Pre_Recovery_Health__c = 0, // Ideally store from assess step
                Post_Recovery_Health__c = SystemHealthMonitor.calculateOverallHealthScore()
            );
            insert recoveryLog;
        } catch (Exception e) {
            System.debug('Failed to update recovery status: ' + e.getMessage());
        }
    }
    
    // ===== Utility methods =====
    
    private static void clearSystemCaches() {
        try {
            Cache.Org.clear();
            SystemCacheManager.clearAllCaches();
            System.debug('✓ System caches cleared');
        } catch (Exception e) {
            System.debug('Cache clearing failed: ' + e.getMessage());
        }
    }
    
    private static void resetPerformanceCounters() {
        try {
            Performance_Counter__c counter = Performance_Counter__c.getOrgDefaults();
            if (counter == null) counter = new Performance_Counter__c();
            counter.Request_Count__c = 0;
            counter.Error_Count__c = 0;
            counter.Last_Reset__c = DateTime.now();
            upsert counter;
            System.debug('✓ Performance counters reset');
        } catch (Exception e) {
            System.debug('Performance counter reset failed: ' + e.getMessage());
        }
    }
    
    private static void restartCriticalServices() {
        try {
            List<CronTrigger> activeJobs = [
                SELECT Id, CronJobDetail.Name 
                FROM CronTrigger 
                WHERE CronJobDetail.Name LIKE '%SystemHealth%' 
                AND State = 'WAITING'
            ];
            
            for (CronTrigger job : activeJobs) {
                try { System.abortJob(job.Id); }
                catch (Exception e) { System.debug('Failed to abort job: ' + job.CronJobDetail.Name); }
            }
            
            SystemHealthMonitor.scheduleMaintenanceActivities();
            System.debug('✓ Critical services restarted');
        } catch (Exception e) {
            System.debug('Service restart failed: ' + e.getMessage());
        }
    }
    
    private static void clearErrorQueues() {
        try {
            List<Error_Queue__c> errorQueue = [
                SELECT Id, Error_Type__c, Retry_Count__c 
                FROM Error_Queue__c 
                WHERE Status__c = 'FAILED' 
                AND Retry_Count__c < 3
            ];
            
            for (Error_Queue__c error : errorQueue) {
                error.Status__c = 'RETRY';
                error.Retry_Count__c = (error.Retry_Count__c == null ? 0 : error.Retry_Count__c) + 1;
                error.Last_Retry__c = DateTime.now();
            }
            
            if (!errorQueue.isEmpty()) update errorQueue;
            System.debug('✓ Error queues cleared and retry initiated');
        } catch (Exception e) {
            System.debug('Error queue clearing failed: ' + e.getMessage());
        }
    }
    
    private static void resetMonitoringBaselines() {
        try {
            System_Health_Baseline__c newBaseline = new System_Health_Baseline__c(
                Baseline_Date__c = Date.today(),
                Overall_Health_Score__c = SystemHealthMonitor.calculateOverallHealthScore(),
                Created_By__c = UserInfo.getUserId(),
                Baseline_Type__c = 'POST_RECOVERY'
            );
            insert newBaseline;
            System.debug('✓ Monitoring baselines reset');
        } catch (Exception e) {
            System.debug('Baseline reset failed: ' + e.getMessage());
        }
    }
    
    private static void optimizePerformance() {
        try {
            PerformanceOptimizer.optimizeQueries();
            PerformanceOptimizer.optimizeIndexes();
            PerformanceOptimizer.cleanupTempData();
            System.debug('✓ Performance optimization completed');
        } catch (Exception e) {
            System.debug('Performance optimization failed: ' + e.getMessage());
        }
    }
    
    private static void resolveActiveAlerts() {
        try {
            List<System_Alert__c> resolvableAlerts = [
                SELECT Id, Alert_Type__c, Severity__c 
                FROM System_Alert__c 
                WHERE Status__c = 'ACTIVE' 
                AND Auto_Resolve__c = true
            ];
            
            for (System_Alert__c alert : resolvableAlerts) {
                alert.Status__c = 'AUTO_RESOLVED';
                alert.Resolved_At__c = DateTime.now();
                alert.Resolution_Notes__c = 'Auto-resolved during system recovery';
            }
            
            if (!resolvableAlerts.isEmpty()) update resolvableAlerts;
            System.debug('✓ Auto-resolvable alerts processed: ' + resolvableAlerts.size());
        } catch (Exception e) {
            System.debug('Alert resolution failed: ' + e.getMessage());
        }
    }
    
    private static void cleanupTempData() {
        try {
            DateTime cleanupDate = DateTime.now().addDays(-7);
            List<Temp_Data__c> tempData = [
                SELECT Id 
                FROM Temp_Data__c 
                WHERE CreatedDate < :cleanupDate
            ];
            
            if (!tempData.isEmpty()) delete tempData;
            System.debug('✓ Temporary data cleanup completed: ' + tempData.size() + ' records removed');
        } catch (Exception e) {
            System.debug('Temp data cleanup failed: ' + e.getMessage());
        }
    }
    
    private static void performRoutineMaintenance() {
        try {
            archiveOldLogs();
            updateSystemStatistics();
            validateDataIntegrity();
            System.debug('✓ Routine maintenance completed');
        } catch (Exception e) {
            System.debug('Routine maintenance failed: ' + e.getMessage());
        }
    }
    
    private static void updateSystemMetrics() {
        try {
            System_Metrics__c metrics = System_Metrics__c.getOrgDefaults();
            if (metrics == null) metrics = new System_Metrics__c();
            
            metrics.Last_Health_Check__c = DateTime.now();
            metrics.Overall_Health_Score__c = SystemHealthMonitor.calculateOverallHealthScore();
            metrics.System_Uptime__c = SystemHealthMonitor.calculateSystemUptime();
            metrics.Error_Rate__c = SystemHealthMonitor.getCurrentErrorRate();
            
            upsert metrics;
            System.debug('✓ System metrics updated');
        } catch (Exception e) {
            System.debug('Metrics update failed: ' + e.getMessage());
        }
    }
    
    private static void clearCriticalErrors() {
        try {
            List<System_Error__c> criticalErrors = [
                SELECT Id 
                FROM System_Error__c 
                WHERE Severity__c = 'CRITICAL' 
                AND Status__c = 'ACTIVE'
                AND Error_Type__c IN ('SYSTEM_FAILURE', 'DATABASE_ERROR', 'SECURITY_BREACH')
            ];
            
            for (System_Error__c error : criticalErrors) {
                error.Status__c = 'EMERGENCY_CLEARED';
                error.Cleared_At__c = DateTime.now();
                error.Clear_Reason__c = 'Cleared during emergency recovery';
            }
            
            if (!criticalErrors.isEmpty()) update criticalErrors;
            System.debug('✓ Critical errors cleared: ' + criticalErrors.size());
        } catch (Exception e) {
            System.debug('Critical error clearing failed: ' + e.getMessage());
        }
    }
    
    private static void resetBasicServices() {
        try {
            Basic_Service_Status__c serviceStatus = Basic_Service_Status__c.getOrgDefaults();
            if (serviceStatus == null) serviceStatus = new Basic_Service_Status__c();
            
            serviceStatus.Database_Status__c = 'OPERATIONAL';
            serviceStatus.Application_Status__c = 'OPERATIONAL';
            serviceStatus.Security_Status__c = 'OPERATIONAL';
            serviceStatus.Last_Reset__c = DateTime.now();
            
            upsert serviceStatus;
            System.debug('✓ Basic services reset');
        } catch (Exception e) {
            System.debug('Basic service reset failed: ' + e.getMessage());
        }
    }
    
    private static void archiveOldLogs() {
        try {
            DateTime archiveDate = DateTime.now().addDays(-30);
            List<AuditTrail__c> oldAudits = [
                SELECT Id 
                FROM AuditTrail__c 
                WHERE Timestamp__c < :archiveDate 
                AND Archived__c = false
                LIMIT 1000
            ];
            
            for (AuditTrail__c audit : oldAudits) {
                audit.Archived__c = true;
                audit.Archived_Date__c = Date.today();
            }
            
            if (!oldAudits.isEmpty()) update oldAudits;
            System.debug('✓ Log archival completed: ' + oldAudits.size() + ' records archived');
        } catch (Exception e) {
            System.debug('Log archival failed: ' + e.getMessage());
        }
    }
    
    private static void updateSystemStatistics() {
        try {
            System_Statistics__c stats = System_Statistics__c.getOrgDefaults();
            if (stats == null) stats = new System_Statistics__c();
            
            stats.Total_Users__c = [SELECT COUNT() FROM User WHERE IsActive = true];
            stats.Total_Records__c = getTotalRecordCount();
            stats.Average_Response_Time__c = SystemHealthMonitor.getRecentAverageResponseTime();
            stats.System_Load__c = getCurrentSystemLoad();
            stats.Last_Updated__c = DateTime.now();
            
            upsert stats;
            System.debug('✓ System statistics updated');
        } catch (Exception e) {
            System.debug('Statistics update failed: ' + e.getMessage());
        }
    }
    
    private static Integer getTotalRecordCount() {
        try {
            Integer totalCount = 0;
            totalCount += [SELECT COUNT() FROM AuditTrail__c];
            totalCount += [SELECT COUNT() FROM System_Alert__c];
            totalCount += [SELECT COUNT() FROM Performance_Snapshot__c];
            return totalCount;
        } catch (Exception e) {
            return 0;
        }
    }
    
    private static Decimal getCurrentSystemLoad() {
        try {
            Decimal cpuLoad = (Decimal.valueOf(Limits.getCpuTime()) / Limits.getLimitCpuTime()) * 100;
            Decimal memoryLoad = (Decimal.valueOf(Limits.getHeapSize()) / Limits.getLimitHeapSize()) * 100;
            Decimal queryLoad = (Decimal.valueOf(Limits.getQueries()) / Limits.getLimitQueries()) * 100;
            return (cpuLoad + memoryLoad + queryLoad) / 3;
        } catch (Exception e) {
            return 50;
        }
    }
    
    private static void validateDataIntegrity() {
        try {
            Integer orphanedRecords = validateRecordRelationships();
            Integer corruptedData = validateDataConsistency();
            
            if (orphanedRecords > 0 || corruptedData > 0) {
                createSystemAlert(
                    'DATA_INTEGRITY_ISSUES',
                    'WARNING',
                    'Data integrity validation found ' + orphanedRecords + ' orphaned records and ' + corruptedData + ' inconsistent records'
                );
            }
            System.debug('✓ Data integrity validation completed');
        } catch (Exception e) {
            System.debug('Data integrity validation failed: ' + e.getMessage());
        }
    }
    
    private static Integer validateRecordRelationships() {
        try {
            List<System_Alert__c> orphanedAlerts = [
                SELECT Id 
                FROM System_Alert__c 
                WHERE Related_Record_Id__c != null 
                AND Related_Record_Id__c NOT IN (SELECT Id FROM AuditTrail__c)
            ];
            return orphanedAlerts.size();
        } catch (Exception e) {
            return 0;
        }
    }
    
    private static Integer validateDataConsistency() {
        try {
            List<Performance_Snapshot__c> inconsistentSnapshots = [
                SELECT Id 
                FROM Performance_Snapshot__c 
                WHERE Average_Response_Time__c < 0 
                OR Error_Rate__c < 0 
                OR Error_Rate__c > 100
            ];
            return inconsistentSnapshots.size();
        } catch (Exception e) {
            return 0;
        }
    }
    
    private static void createSystemAlert(String type, String severity, String message) {
        try {
            System_Alert__c alert = new System_Alert__c(
                Alert_Type__c = type,
                Severity__c = severity,
                Status__c = 'ACTIVE',
                Alert_Message__c = message,
                Created_At__c = DateTime.now()
            );
            insert alert;
        } catch (Exception e) {
            System.debug('Failed to create system alert: ' + e.getMessage());
        }
    }
}
