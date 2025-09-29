public class PerformanceMonitorSchedulable implements Schedulable {
    public void execute(SchedulableContext sc) {
        try {
            // Collect performance metrics
            Map<String, Object> performanceData = collectPerformanceMetrics();
            
            // Store performance snapshot
            Performance_Snapshot__c snapshot = new Performance_Snapshot__c(
                Snapshot_Time__c       = DateTime.now(),
                Average_Response_Time__c = (Decimal)performanceData.get('avgResponseTime'),
                Error_Rate__c          = (Decimal)performanceData.get('errorRate'),
                Throughput__c          = (Integer)performanceData.get('throughput'),
                Active_Users__c        = (Integer)performanceData.get('activeUsers'),
                System_Load__c         = (Decimal)performanceData.get('systemLoad'),
                Memory_Usage__c        = (Decimal)performanceData.get('memoryUsage'),
                CPU_Usage__c           = (Decimal)performanceData.get('cpuUsage')
            );
            insert snapshot;

            // Check performance thresholds
            checkPerformanceThresholds(performanceData);
            
            // Log successful monitoring execution
            System_Monitoring_Log__c perfLog = new System_Monitoring_Log__c(
                Log_Type__c        = 'PERFORMANCE_MONITOR',
                Execution_Time__c  = DateTime.now(),
                Status__c          = 'SUCCESS',
                Details__c         = 'Performance monitoring completed successfully',
                Performance_Score__c = calculatePerformanceScore(performanceData),
                Executed_By__c     = 'SYSTEM'
            );
            insert perfLog;
            
        } catch (Exception e) {
            // Log monitoring failure
            System_Monitoring_Log__c errorLog = new System_Monitoring_Log__c(
                Log_Type__c        = 'PERFORMANCE_MONITOR',
                Execution_Time__c  = DateTime.now(),
                Status__c          = 'ERROR',
                Details__c         = 'Performance monitoring failed: ' + e.getMessage(),
                Error_Message__c   = e.getStackTraceString(),
                Executed_By__c     = 'SYSTEM'
            );
            insert errorLog;
        }
    }

    private Map<String, Object> collectPerformanceMetrics() {
        Map<String, Object> metrics = new Map<String, Object>();
        DateTime oneHourAgo = DateTime.now().addHours(-1);

        // Average response time
        List<AggregateResult> responseTimeData = [
            SELECT AVG(Response_Time_Ms__c) avgTime
            FROM Performance_Log__c 
            WHERE CreatedDate >= :oneHourAgo
        ];
        metrics.put(
            'avgResponseTime', 
            !responseTimeData.isEmpty() && responseTimeData[0].get('avgTime') != null ? 
            (Decimal)responseTimeData[0].get('avgTime') : 0
        );

        // Error rate calculation (fixed CASE issue)
        Integer totalOps = [
            SELECT COUNT() 
            FROM AuditTrail__c 
            WHERE Timestamp__c >= :oneHourAgo
        ];
        Integer errorOps = [
            SELECT COUNT() 
            FROM AuditTrail__c 
            WHERE Timestamp__c >= :oneHourAgo
            AND Status__c = 'ERROR'
        ];
        Decimal errorRate = totalOps > 0 ? (Decimal.valueOf(errorOps) / totalOps * 100) : 0;
        metrics.put('errorRate', errorRate);

        // Current system load indicators
        metrics.put('memoryUsage', Limits.getHeapSize());
        metrics.put('cpuUsage', Limits.getCpuTime());
        metrics.put('soqlQueries', Limits.getQueries());
        metrics.put('dmlStatements', Limits.getDmlStatements());

        // Active users (approximate)
        Integer activeUsers = [
            SELECT COUNT_DISTINCT(CreatedById) 
            FROM AuditTrail__c 
            WHERE Timestamp__c >= :oneHourAgo
        ];
        metrics.put('activeUsers', activeUsers);

        // Throughput (operations per hour)
        Integer throughput = [
            SELECT COUNT() 
            FROM AuditTrail__c 
            WHERE Timestamp__c >= :oneHourAgo
        ];
        metrics.put('throughput', throughput);

        // Example system load (you can refine this calc)
        metrics.put('systemLoad', (Decimal)Limits.getCpuTime() / Limits.getLimitCpuTime() * 100);

        return metrics;
    }

    private void checkPerformanceThresholds(Map<String, Object> performanceData) {
        List<Alert_Threshold__c> thresholds = [
            SELECT Metric_Type__c, Warning_Threshold__c, Critical_Threshold__c
            FROM Alert_Threshold__c 
            WHERE Is_Active__c = true
        ];

        for (Alert_Threshold__c threshold : thresholds) {
            checkIndividualThreshold(threshold, performanceData);
        }
    }

    private void checkIndividualThreshold(Alert_Threshold__c threshold, Map<String, Object> performanceData) {
        String metricKey = getMetricKey(threshold.Metric_Type__c);
        if (!performanceData.containsKey(metricKey)) return;

        Decimal currentValue = (Decimal)performanceData.get(metricKey);
        String severity, message;

        if (currentValue >= threshold.Critical_Threshold__c) {
            severity = 'CRITICAL';
            message  = threshold.Metric_Type__c + ' has reached critical level: ' + currentValue;
        } else if (currentValue >= threshold.Warning_Threshold__c) {
            severity = 'HIGH';
            message  = threshold.Metric_Type__c + ' has exceeded warning threshold: ' + currentValue;
        } else {
            return; // within safe limits
        }

        createPerformanceAlert(severity, message, threshold.Metric_Type__c, currentValue);
    }

    private String getMetricKey(String metricType) {
        switch on metricType {
            when 'RESPONSE_TIME' { return 'avgResponseTime'; }
            when 'ERROR_RATE'    { return 'errorRate'; }
            when 'CPU_USAGE'     { return 'cpuUsage'; }
            when 'MEMORY_USAGE'  { return 'memoryUsage'; }
            when else            { return 'unknown'; }
        }
    }

    private void createPerformanceAlert(String severity, String message, String metricType, Decimal value) {
        try {
            System_Alert__c alert = new System_Alert__c(
                Alert_Type__c       = 'PERFORMANCE_THRESHOLD',
                Severity__c         = severity,
                Title__c            = 'Performance Threshold Exceeded',
                Message__c          = message,
                Details__c          = 'Metric: ' + metricType + ', Current Value: ' + value,
                Status__c           = 'ACTIVE',
                Triggered_At__c     = DateTime.now(),
                Source_System__c    = 'PERFORMANCE_MONITOR',
                Requires_Attention__c = true
            );
            insert alert;
        } catch (Exception e) {
            System.debug('Failed to create performance alert: ' + e.getMessage());
        }
    }

    private Decimal calculatePerformanceScore(Map<String, Object> performanceData) {
        Decimal score = 100;

        // Response time impact
        Decimal avgResponseTime = (Decimal)performanceData.get('avgResponseTime');
        if (avgResponseTime > 5000)      score -= 40;
        else if (avgResponseTime > 3000) score -= 25;
        else if (avgResponseTime > 2000) score -= 15;

        // Error rate impact
        Decimal errorRate = (Decimal)performanceData.get('errorRate');
        if (errorRate > 10)      score -= 50;
        else if (errorRate > 5)  score -= 30;
        else if (errorRate > 2)  score -= 15;

        return Math.max(0, score);
    }
}
