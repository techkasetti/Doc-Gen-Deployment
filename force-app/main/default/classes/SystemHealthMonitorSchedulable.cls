// Schedulable class for automated monitoring
public class SystemHealthMonitorSchedulable implements Schedulable {
    public void execute(SchedulableContext sc) {
        try {
            // Execute health monitoring
            Map<String, Object> healthStatus = ProductionMonitoringService.performComprehensiveHealthCheck();
            
            // Extract critical issues safely
            List<String> criticalIssues = new List<String>();
            if (healthStatus.containsKey('criticalIssues')) {
                criticalIssues = (List<String>)healthStatus.get('criticalIssues');
                if (!criticalIssues.isEmpty()) {
                    generateHealthAlerts(criticalIssues);
                }
            }
            
            // Log monitoring execution
            System_Monitoring_Log__c monitoringLog = new System_Monitoring_Log__c(
                Log_Type__c = 'HEALTH_CHECK',
                Execution_Time__c = DateTime.now(),
                Status__c = 'SUCCESS',
                Details__c = 'Automated health monitoring executed successfully',
                Health_Score__c = (Decimal)healthStatus.get('overallHealthScore'),
                Issues_Found__c = criticalIssues.size(),
                Executed_By__c = 'SYSTEM'
            );
            insert monitoringLog;

        } catch (Exception e) {
            // Log monitoring failure
            System_Monitoring_Log__c errorLog = new System_Monitoring_Log__c(
                Log_Type__c = 'HEALTH_CHECK',
                Execution_Time__c = DateTime.now(),
                Status__c = 'ERROR',
                Details__c = 'Health monitoring failed: ' + e.getMessage(),
                Error_Message__c = e.getStackTraceString(),
                Executed_By__c = 'SYSTEM'
            );
            insert errorLog;

            // Generate critical alert for monitoring system failure
            generateCriticalAlert(
                'MONITORING_FAILURE',
                'Health monitoring system encountered an error',
                e.getMessage()
            );
        }
    }

    private void generateHealthAlerts(List<String> criticalIssues) {
        try {
            for (String issue : criticalIssues) {
                System_Alert__c alert = new System_Alert__c(
                    Alert_Type__c = 'HEALTH_CHECK',
                    Severity__c = 'CRITICAL',
                    Title__c = 'Critical System Health Issue',
                    Message__c = issue,
                    Status__c = 'ACTIVE',
                    Triggered_At__c = DateTime.now(),
                    Source_System__c = 'HEALTH_MONITOR',
                    Requires_Attention__c = true
                );
                insert alert;
            }
        } catch (Exception e) {
            System.debug('Failed to generate health alerts: ' + e.getMessage());
        }
    }

    private void generateCriticalAlert(String alertType, String message, String details) {
        try {
            System_Alert__c criticalAlert = new System_Alert__c(
                Alert_Type__c = alertType,
                Severity__c = 'CRITICAL',
                Title__c = 'System Monitoring Failure',
                Message__c = message,
                Details__c = details,
                Status__c = 'ACTIVE',
                Triggered_At__c = DateTime.now(),
                Source_System__c = 'MONITORING_SYSTEM',
                Requires_Attention__c = true,
                Escalated__c = true
            );
            insert criticalAlert;
        } catch (Exception e) {
            System.debug('CRITICAL: Unable to create monitoring failure alert: ' + e.getMessage());
        }
    }
}
