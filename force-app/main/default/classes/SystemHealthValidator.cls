// System Health Validator Class
public class SystemHealthValidator {
    
    public class ValidationResult {
        @AuraEnabled public Boolean isValid { get; set; }
        @AuraEnabled public String component { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public String severity { get; set; }
        @AuraEnabled public DateTime timestamp { get; set; }
    }

    public class ComponentStatus {
        @AuraEnabled public String componentName { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public String details { get; set; }
        @AuraEnabled public String severity { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static List<ValidationResult> performSystemHealthCheck() {
        List<ValidationResult> results = new List<ValidationResult>();
        DateTime checkTime = DateTime.now();

        // Check core monitoring system
        results.addAll(validateCoreMonitoring(checkTime));

        // Validate alert system
        results.addAll(validateAlertSystem(checkTime));

        // Check data consistency
        results.addAll(validateDataConsistency(checkTime));

        // Validate analytics engine
        results.addAll(validateAnalyticsEngine(checkTime));

        // Check system integrations
        results.addAll(validateIntegrations(checkTime));

        // Add performance validation
        results.addAll(validatePerformance(checkTime));

        return results;
    }

    private static List<ValidationResult> validateCoreMonitoring(DateTime checkTime) {
        List<ValidationResult> results = new List<ValidationResult>();

        try {
            MonitoringService.MonitoringConfiguration config = MonitoringService.getCurrentConfiguration();

            if (config == null) {
                results.add(createResult('Core Monitoring', 'No configuration found', 'CRITICAL', checkTime));
            } else {
                if (config.enableRealTimeAlerts == false) {
                    results.add(createResult('Core Monitoring', 'Real-time alerts are disabled', 'WARNING', checkTime));
                }
                if (config.performanceThreshold == null || config.complianceThreshold == null) {
                    results.add(createResult('Core Monitoring', 'Thresholds not properly configured', 'CRITICAL', checkTime));
                }
            }
        } catch (Exception e) {
            results.add(createResult('Core Monitoring', 'Error: ' + e.getMessage(), 'CRITICAL', checkTime));
        }

        return results;
    }

    private static List<ValidationResult> validateAlertSystem(DateTime checkTime) {
        List<ValidationResult> results = new List<ValidationResult>();

        try {
            List<RealTimeMonitoringService.SystemAlert> recentAlerts = [
                SELECT Id, AlertType__c, Severity__c, Status__c, CreatedDate 
                FROM System_Alert__c 
                WHERE CreatedDate = LAST_N_DAYS:1
                ORDER BY CreatedDate DESC
                LIMIT 10
            ];

            if (recentAlerts.isEmpty()) {
                results.add(createResult('Alert System', 'No alerts generated in last 24 hours', 'WARNING', checkTime));
            }

            Integer unresolvedCount = [SELECT COUNT() FROM System_Alert__c WHERE Status__c = 'OPEN'];
            if (unresolvedCount > 100) {
                results.add(createResult('Alert System', 'High number of unresolved alerts: ' + unresolvedCount, 'CRITICAL', checkTime));
            }
        } catch (Exception e) {
            results.add(createResult('Alert System', 'Error checking alerts: ' + e.getMessage(), 'CRITICAL', checkTime));
        }

        return results;
    }

    private static List<ValidationResult> validateDataConsistency(DateTime checkTime) {
        List<ValidationResult> results = new List<ValidationResult>();

        try {
            AggregateResult[] complianceStats = [
                SELECT COUNT(Id) recordCount, AVG(Overall_Compliance_Score__c) avgScore
                FROM DocumentLifecycleConfiguration__c
                WHERE CreatedDate = LAST_N_DAYS:30
            ];

            if (!complianceStats.isEmpty()) {
                Decimal avgScore = (Decimal) complianceStats[0].get('avgScore');
                if (avgScore < 70) {
                    results.add(createResult('Data Consistency', 'Low average compliance score: ' + avgScore, 'CRITICAL', checkTime));
                }
            }
        } catch (Exception e) {
            results.add(createResult('Data Consistency', 'Error validating data: ' + e.getMessage(), 'CRITICAL', checkTime));
        }

        return results;
    }

    private static List<ValidationResult> validateAnalyticsEngine(DateTime checkTime) {
        List<ValidationResult> results = new List<ValidationResult>();

        try {
            SystemHealthMonitor.HealthMetrics healthMetrics = SystemHealthMonitor.getCurrentHealthMetrics();

            if (healthMetrics == null) {
                results.add(createResult('Analytics Engine', 'Health metrics not available', 'CRITICAL', checkTime));
            } else {
                if (healthMetrics.complianceScore < 80) {
                    results.add(createResult('Analytics Engine', 'Low compliance score: ' + healthMetrics.complianceScore, 'CRITICAL', checkTime));
                }
                if (healthMetrics.performanceScore < 80) {
                    results.add(createResult('Analytics Engine', 'Low performance score: ' + healthMetrics.performanceScore, 'WARNING', checkTime));
                }
            }
        } catch (Exception e) {
            results.add(createResult('Analytics Engine', 'Error validating analytics engine: ' + e.getMessage(), 'CRITICAL', checkTime));
        }

        return results;
    }

    private static List<ValidationResult> validateIntegrations(DateTime checkTime) {
        List<ValidationResult> results = new List<ValidationResult>();

        try {
            List<System_Integration__c> integrations = [
                SELECT Id, Name, Status__c, LastCheck__c 
                FROM System_Integration__c
            ];

            for (System_Integration__c integration : integrations) {
                if (integration.Status__c != 'ACTIVE') {
                    results.add(createResult(
                        'Integration: ' + integration.Name,
                        'Integration not active',
                        'CRITICAL',
                        checkTime
                    ));
                }
                if (integration.LastCheck__c == null || integration.LastCheck__c < System.today().addDays(-1)) {
                    results.add(createResult(
                        'Integration: ' + integration.Name,
                        'Integration check outdated',
                        'WARNING',
                        checkTime
                    ));
                }
            }
        } catch (Exception e) {
            results.add(createResult('System Integrations', 'Error validating integrations: ' + e.getMessage(), 'CRITICAL', checkTime));
        }

        return results;
    }

    private static List<ValidationResult> validatePerformance(DateTime checkTime) {
        List<ValidationResult> results = new List<ValidationResult>();

        try {
            // List<Performance_Metrics__c> recentMetrics = [
            //     SELECT Response_Time_Ms__c, Generation_Time_Ms__c, Error_Rate__c, Timestamp__c
            //     FROM Performance_Metrics__c
            //     WHERE Timestamp__c = LAST_N_HOURS:24
            //     ORDER BY Timestamp__c DESC
            //     LIMIT 100
            // ];
            List<Performance_Metrics__c> recentMetrics = [
                SELECT Response_Time_Ms__c,
                    Generation_Time_Ms__c,
                    Error_Rate__c,
                    Timestamp__c
                FROM Performance_Metrics__c
                WHERE Timestamp__c >= :System.now().addHours(-24)
                ORDER BY Timestamp__c DESC
                LIMIT 100
            ];


            if (!recentMetrics.isEmpty()) {
                for (Performance_Metrics__c metric : recentMetrics) {
                    if (metric.Response_Time_Ms__c > 5000) {
                        results.add(createResult('Performance', 'High response time detected: ' + metric.Response_Time_Ms__c + 'ms', 'WARNING', checkTime));
                    }
                    if (metric.Error_Rate__c > 5) {
                        results.add(createResult('Performance', 'High error rate detected: ' + metric.Error_Rate__c + '%', 'CRITICAL', checkTime));
                    }
                }
            }
        } catch (Exception e) {
            results.add(createResult('Performance', 'Error validating performance: ' + e.getMessage(), 'CRITICAL', checkTime));
        }

        return results;
    }

    private static ValidationResult createResult(String component, String message, String severity, DateTime timestamp) {
        ValidationResult result = new ValidationResult();
        result.isValid = (severity != 'CRITICAL');
        result.component = component;
        result.message = message;
        result.severity = severity;
        result.timestamp = timestamp;
        return result;
    }
}




