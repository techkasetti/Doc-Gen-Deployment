public class PerformanceMonitoringService {

    public class PerformanceMetric {
        @AuraEnabled public String operationType { get; set; }
        @AuraEnabled public Decimal executionTime { get; set; }
        @AuraEnabled public Boolean slaCompliant { get; set; }
        @AuraEnabled public DateTime timestamp { get; set; }
        @AuraEnabled public String status { get; set; }
    }

    // SLA Thresholds (in seconds)
    private static final Map<String, Decimal> SLA_THRESHOLDS = new Map<String, Decimal> {
        'DOCUMENT_GENERATION' => 5.0,
        'SIGNATURE_REQUEST' => 3.0,
        'COMPLIANCE_CHECK' => 2.0,
        'TEMPLATE_RENDERING' => 1.0,
        'BULK_PROCESSING' => 600.0
    };

    @future
    public static void recordPerformanceMetric(String operationType, Decimal executionTime, Id relatedRecordId) {
        try {
            Boolean slaCompliant = checkSLACompliance(operationType, executionTime);

            PerformanceBenchmark__c benchmark = new PerformanceBenchmark__c(
                OperationType__c = operationType,
                ExecutionTime__c = executionTime,
                SLACompliant__c = slaCompliant,
                RelatedRecordId__c = relatedRecordId,
                Timestamp__c = System.now()
            );
            insert benchmark;

            // Create alert for SLA violations
            if (!slaCompliant) {
                SystemAlertManager.createAlert(
                    SystemAlertManager.AlertType.PERFORMANCE_DEGRADATION,
                    'SLA violation detected for ' + operationType + ': ' + executionTime + 's (threshold: ' + SLA_THRESHOLDS.get(operationType) + 's)',
                    SystemAlertManager.AlertPriority.HIGH,
                    relatedRecordId
                );

                // Publish platform event for real-time notifications
                publishSLAViolationEvent(operationType, executionTime, relatedRecordId);
            }

        } catch (Exception e) {
            System.debug('Failed to record performance metric: ' + e.getMessage());
        }
    }

    public static Boolean checkSLACompliance(String operationType, Decimal executionTime) {
        Decimal threshold = SLA_THRESHOLDS.get(operationType);
        return threshold != null ? executionTime <= threshold : true;
    }

    private static void publishSLAViolationEvent(String operationType, Decimal executionTime, Id relatedRecordId) {
        try {
            SLA_Violation__e event = new SLA_Violation__e(
                OperationType__c = operationType,
                ExecutionTime__c = executionTime,
                ViolationSeverity__c = calculateViolationSeverity(operationType, executionTime),
                RelatedRecordId__c = relatedRecordId,
                OrganizationId__c = UserInfo.getOrganizationId()
            );

            Database.SaveResult result = EventBus.publish(event);

            if (!result.isSuccess()) {
                System.debug('Failed to publish SLA violation event: ' + result.getErrors());
            }
        } catch (Exception e) {
            System.debug('Error publishing SLA violation event: ' + e.getMessage());
        }
    }

    private static String calculateViolationSeverity(String operationType, Decimal executionTime) {
        Decimal threshold = SLA_THRESHOLDS.get(operationType);
        if (threshold == null) return 'UNKNOWN';

        Decimal violationRatio = executionTime / threshold;

        if (violationRatio > 3) return 'CRITICAL';
        if (violationRatio > 2) return 'HIGH';
        if (violationRatio > 1.5) return 'MEDIUM';
        return 'LOW';
    }

    @AuraEnabled(cacheable=true)
    public static List<PerformanceMetric> getRecentPerformanceMetrics(Integer limitCount, String operationType) {
        List<PerformanceMetric> metrics = new List<PerformanceMetric>();

        String query = 'SELECT OperationType__c, ExecutionTime__c, SLACompliant__c, Timestamp__c FROM PerformanceBenchmark__c';

        if (String.isNotBlank(operationType)) {
            query += ' WHERE OperationType__c = \'' + String.escapeSingleQuotes(operationType) + '\'';
        }

        query += ' ORDER BY Timestamp__c DESC LIMIT ' + limitCount;

        List<PerformanceBenchmark__c> benchmarks = Database.query(query);

        for (PerformanceBenchmark__c benchmark : benchmarks) {
            PerformanceMetric metric = new PerformanceMetric();
            metric.operationType = benchmark.OperationType__c;
            metric.executionTime = benchmark.ExecutionTime__c;
            metric.slaCompliant = benchmark.SLACompliant__c;
            metric.timestamp = benchmark.Timestamp__c;
            metric.status = benchmark.SLACompliant__c ? 'COMPLIANT' : 'VIOLATION';
            metrics.add(metric);
        }

        return metrics;
    }

    @AuraEnabled
    public static Map<String, Object> getPerformanceSummary(String timeframe) {
        DateTime startTime = getStartTimeForTimeframe(timeframe);

       List<AggregateResult> results = [
    SELECT OperationType__c, 
           AVG(ExecutionTime__c) avgTime,
           COUNT(Id) totalOperations,
           COUNT(Id) totalViolations
    FROM PerformanceBenchmark__c
    WHERE Timestamp__c >= :startTime
    GROUP BY OperationType__c
];


        Map<String, Object> summary = new Map<String, Object>();
        List<Map<String, Object>> operationSummaries = new List<Map<String, Object>>();

        Integer totalOperations = 0;
        Integer totalViolations = 0;

        for (AggregateResult result : results) {
            String operationType = (String)result.get('OperationType__c');
            Decimal avgTime = (Decimal)result.get('avgTime');
            Integer opCount = (Integer)result.get('totalOperations');
            Integer violations = (Integer)result.get('violations');

            totalOperations += opCount;
            totalViolations += violations;

            Decimal slaThreshold = SLA_THRESHOLDS.get(operationType);

            operationSummaries.add(new Map<String, Object> {
                'operationType' => operationType,
                'averageTime' => avgTime != null ? avgTime.setScale(2) : null,
                'totalOperations' => opCount,
                'violations' => violations,
                'slaThreshold' => slaThreshold,
                'complianceRate' => opCount > 0 ? ((opCount - violations) * 100.0 / opCount).setScale(1) : 100,
                'status' => avgTime != null && slaThreshold != null && avgTime <= slaThreshold ? 'HEALTHY' : 'AT_RISK'
            });
        }

        summary.put('operationSummaries', operationSummaries);
        summary.put('totalOperations', totalOperations);
        summary.put('totalViolations', totalViolations);
        summary.put('overallComplianceRate', totalOperations > 0 ? ((totalOperations - totalViolations) * 100.0 / totalOperations).setScale(1) : 100);
        summary.put('lastUpdated', System.now());

        return summary;
    }

    private static DateTime getStartTimeForTimeframe(String timeframe) {
        switch on timeframe {
            when 'LAST_HOUR' {
                return DateTime.now().addHours(-1);
            }
            when 'LAST_24_HOURS' {
                return DateTime.now().addHours(-24);
            }
            when 'LAST_7_DAYS' {
                return DateTime.now().addDays(-7);
            }
            when 'LAST_30_DAYS' {
                return DateTime.now().addDays(-30);
            }
            when else {
                return DateTime.now().addHours(-24); // Default to last 24 hours
            }
        }
    }

    // Method to track operation performance (to be called from other services)
    public static void trackOperation(String operationType, DateTime startTime, Id relatedRecordId) {
        Decimal executionTime = (System.now().getTime() - startTime.getTime()) / 1000.0;
        recordPerformanceMetric(operationType, executionTime, relatedRecordId);
    }
}