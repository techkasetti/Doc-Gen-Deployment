public with sharing class PerformanceMonitor {
    // Custom exception for unsupported report types
    public class PerformanceException extends Exception {}

    // --------------------
    // CORE PERFORMANCE
    // --------------------
    @AuraEnabled
    public static Map<String, Object> getSystemPerformance() {
        Map<String, Object> performance = new Map<String, Object>();
        try {
            // Governor limits - use a name that does NOT collide with the Limits class
            Map<String, Object> governorLimits = new Map<String, Object>();
            governorLimits.put('soqlQueries', String.valueOf(Limits.getQueries()) + '/' + String.valueOf(Limits.getLimitQueries()));
            governorLimits.put('soqlRows', String.valueOf(Limits.getQueryRows()) + '/' + String.valueOf(Limits.getLimitQueryRows()));
            governorLimits.put('dmlStatements', String.valueOf(Limits.getDMLStatements()) + '/' + String.valueOf(Limits.getLimitDMLStatements()));
            governorLimits.put('dmlRows', String.valueOf(Limits.getDMLRows()) + '/' + String.valueOf(Limits.getLimitDMLRows()));
            governorLimits.put('cpuTime', String.valueOf(Limits.getCpuTime()) + '/' + String.valueOf(Limits.getLimitCpuTime()));
            governorLimits.put('heapSize', String.valueOf(Limits.getHeapSize()) + '/' + String.valueOf(Limits.getLimitHeapSize()));

            // Calculate usage percentages
            Map<String, Decimal> usagePercentages = new Map<String, Decimal>();
            usagePercentages.put('soqlUsage', calculateUsagePercentage(Limits.getQueries(), Limits.getLimitQueries()));
            usagePercentages.put('cpuUsage', calculateUsagePercentage(Limits.getCpuTime(), Limits.getLimitCpuTime()));
            usagePercentages.put('heapUsage', calculateUsagePercentage(Limits.getHeapSize(), Limits.getLimitHeapSize()));
            usagePercentages.put('dmlUsage', calculateUsagePercentage(Limits.getDMLStatements(), Limits.getLimitDMLStatements()));

            // System health indicators
            Map<String, Object> healthIndicators = new Map<String, Object>();
            healthIndicators.put('overallHealth', calculateOverallHealth(usagePercentages));
            healthIndicators.put('performanceGrade', getPerformanceGrade(usagePercentages));
            healthIndicators.put('recommendations', generatePerformanceRecommendations(usagePercentages));

            performance.put('success', true);
            performance.put('governorLimits', governorLimits);
            performance.put('usagePercentages', usagePercentages);
            performance.put('healthIndicators', healthIndicators);
            performance.put('timestamp', DateTime.now());
        } catch (Exception e) {
            performance.put('success', false);
            performance.put('error', e.getMessage());
        }
        return performance;
    }

    // --------------------
    // OPERATION MEASUREMENT
    // --------------------
    @AuraEnabled
    public static Map<String, Object> measureOperationPerformance(String operationType, String operationId) {
        Map<String, Object> result = new Map<String, Object>();
        Long startTime = System.currentTimeMillis();
        try {
            // Record initial resource usage
            Integer initialQueries = Limits.getQueries();
            Integer initialCpuTime = Limits.getCpuTime();
            Integer initialHeapSize = Limits.getHeapSize();

            // NOTE: You should perform the actual operation here. This method measures resources used
            // in this transaction. We do NOT call Thread.sleep (not supported in Apex).
            // If you want to measure a block, call that block before/after invoking this helper.

            // Calculate resource consumption
            Long executionTime = System.currentTimeMillis() - startTime;
            Integer queriesUsed = Limits.getQueries() - initialQueries;
            Integer cpuUsed = Limits.getCpuTime() - initialCpuTime;
            Integer heapUsed = Limits.getHeapSize() - initialHeapSize;

            // Create performance record
            // This assumes a custom object Performance_Metric__c exists in your org.
            Performance_Metric__c metric = new Performance_Metric__c(
                Operation_Type__c = operationType,
                Operation_Id__c = operationId,
                Execution_Time__c = executionTime,
                Queries_Used__c = queriesUsed,
                CPU_Time_Used__c = cpuUsed,
                Heap_Size_Used__c = heapUsed,
                Timestamp__c = DateTime.now()
            );
            insert metric;

            result.put('success', true);
            result.put('executionTime', executionTime);
            result.put('queriesUsed', queriesUsed);
            result.put('cpuTimeUsed', cpuUsed);
            result.put('heapSizeUsed', heapUsed);
            result.put('performanceId', metric.Id);
        } catch (Exception e) {
            result.put('success', false);
            result.put('error', e.getMessage());
        }
        return result;
    }

    // --------------------
    // PERFORMANCE TRENDS
    // --------------------
    @AuraEnabled
    public static Map<String, Object> getPerformanceTrends(String timeframe, String metricType) {
        Map<String, Object> trends = new Map<String, Object>();
        try {
            DateTime startDate = calculateTimeframe(timeframe);

            List<AggregateResult> trendData;
            if (String.isBlank(metricType)) {
                trendData = [
                    SELECT  AVG(Execution_Time__c) avgTime, AVG(Queries_Used__c) avgQueries, AVG(CPU_Time_Used__c) avgCpu, COUNT(Id) operationCount
                    FROM Performance_Metric__c
                    WHERE Timestamp__c >= :startDate
                    
                    
                ];
            } else {
                trendData = [
                    SELECT  AVG(Execution_Time__c) avgTime, AVG(Queries_Used__c) avgQueries, AVG(CPU_Time_Used__c) avgCpu, COUNT(Id) operationCount
                    FROM Performance_Metric__c
                    WHERE Timestamp__c >= :startDate AND Operation_Type__c = :metricType
                    
                ];
            }

            List<Map<String, Object>> hourlyTrends = new List<Map<String, Object>>();
            for (AggregateResult ar : trendData) {
                Map<String, Object> hourlyData = new Map<String, Object>();
                hourlyData.put('hour', ar.get('hour'));
                hourlyData.put('averageTime', ar.get('avgTime'));
                hourlyData.put('averageQueries', ar.get('avgQueries'));
                hourlyData.put('averageCpu', ar.get('avgCpu'));
                hourlyData.put('operationCount', ar.get('operationCount'));
                hourlyTrends.add(hourlyData);
            }

            trends.put('success', true);
            trends.put('hourlyTrends', hourlyTrends);
            trends.put('timeframe', timeframe);
            trends.put('metricType', metricType);
        } catch (Exception e) {
            trends.put('success', false);
            trends.put('error', e.getMessage());
        }
        return trends;
    }

    // --------------------
    // BOTTLENECK IDENTIFICATION
    // --------------------
    @AuraEnabled
    public static Map<String, Object> identifyPerformanceBottlenecks() {
        Map<String, Object> bottlenecks = new Map<String, Object>();
        try {
            List<Map<String, Object>> issues = new List<Map<String, Object>>();

            DateTime since = DateTime.now().addHours(-24);

            // Slow operations (avg execution time > 5000 ms)
            List<AggregateResult> slowOperations = [
                SELECT Operation_Type__c, AVG(Execution_Time__c) avgTime, COUNT(Id) operationCount
                FROM Performance_Metric__c
                WHERE Timestamp__c >= :since
                GROUP BY Operation_Type__c
                HAVING AVG(Execution_Time__c) > 5000
                ORDER BY AVG(Execution_Time__c) DESC
            ];
            for (AggregateResult slowOp : slowOperations) {
                Map<String, Object> issue = new Map<String, Object>();
                issue.put('type', 'SLOW_OPERATION');
                issue.put('operationType', slowOp.get('Operation_Type__c'));
                issue.put('averageTime', slowOp.get('avgTime'));
                issue.put('operationCount', slowOp.get('operationCount'));
                issue.put('severity', 'HIGH');
                issue.put('recommendation', 'Optimize ' + String.valueOf(slowOp.get('Operation_Type__c')) + ' operations');
                issues.add(issue);
            }

            // High CPU usage operations
            List<AggregateResult> resourceHeavyOps = [
                SELECT Operation_Type__c, AVG(CPU_Time_Used__c) avgCpu, AVG(Queries_Used__c) avgQueries
                FROM Performance_Metric__c
                WHERE Timestamp__c >= :since
                GROUP BY Operation_Type__c
                HAVING AVG(CPU_Time_Used__c) > 10000
                ORDER BY AVG(CPU_Time_Used__c) DESC
            ];
            for (AggregateResult heavyOp : resourceHeavyOps) {
                Map<String, Object> issue = new Map<String, Object>();
                issue.put('type', 'HIGH_RESOURCE_USAGE');
                issue.put('operationType', heavyOp.get('Operation_Type__c'));
                issue.put('averageCpu', heavyOp.get('avgCpu'));
                issue.put('averageQueries', heavyOp.get('avgQueries'));
                issue.put('severity', 'MEDIUM');
                issue.put('recommendation', 'Review resource usage for ' + String.valueOf(heavyOp.get('Operation_Type__c')));
                issues.add(issue);
            }

            bottlenecks.put('success', true);
            bottlenecks.put('issues', issues);
            bottlenecks.put('totalIssues', issues.size());
            bottlenecks.put('analysisDate', DateTime.now());
            bottlenecks.put('recommendations', generateBottleneckRecommendations(issues));
        } catch (Exception e) {
            bottlenecks.put('success', false);
            bottlenecks.put('error', e.getMessage());
        }
        return bottlenecks;
    }

    // --------------------
    // PERFORMANCE REPORTS
    // --------------------
    @AuraEnabled
    public static Map<String, Object> generatePerformanceReport(String reportType, String timeframe) {
        Map<String, Object> report = new Map<String, Object>();
        try {
            DateTime startDate = calculateTimeframe(timeframe);
            Map<String, Object> body;
            switch on reportType {
                when 'EXECUTIVE_SUMMARY' {
                    body = generateExecutiveSummary(startDate);
                }
                when 'DETAILED_ANALYSIS' {
                    body = generateDetailedAnalysis(startDate);
                }
                when 'BOTTLENECK_ANALYSIS' {
                    body = generateBottleneckAnalysis(startDate);
                }
                when else {
                    throw new PerformanceException('Unsupported report type: ' + reportType);
                }
            }
            report.put('success', true);
            report.put('reportType', reportType);
            report.put('timeframe', timeframe);
            report.put('generatedDate', DateTime.now());
            report.put('body', body);
        } catch (Exception e) {
            report.put('success', false);
            report.put('error', e.getMessage());
        }
        return report;
    }

    // --------------------
    // THRESHOLDS & ALERTS
    // --------------------
    @AuraEnabled
    public static Map<String, Object> setPerformanceThreshold(String metricType, Decimal threshold, String severity) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            Performance_Threshold__c perfThreshold = new Performance_Threshold__c(
                Metric_Type__c = metricType,
                Threshold_Value__c = threshold,
                Severity__c = severity,
                Is_Active__c = true,
                Created_By__c = UserInfo.getUserId(),
                Created_Date__c = DateTime.now()
            );
            insert perfThreshold;
            result.put('success', true);
            result.put('thresholdId', perfThreshold.Id);
            result.put('message', 'Performance threshold set successfully');
        } catch (Exception e) {
            result.put('success', false);
            result.put('error', e.getMessage());
        }
        return result;
    }

    @AuraEnabled
    public static Map<String, Object> checkPerformanceAlerts() {
        Map<String, Object> alerts = new Map<String, Object>();
        try {
            List<Map<String, Object>> activeAlerts = new List<Map<String, Object>>();
            List<Performance_Threshold__c> thresholds = [
                SELECT Id, Metric_Type__c, Threshold_Value__c, Severity__c
                FROM Performance_Threshold__c
                WHERE Is_Active__c = true
            ];

            DateTime oneHourAgo = DateTime.now().addHours(-1);
            for (Performance_Threshold__c threshold : thresholds) {
                // get recent average execution time for metric type
                List<AggregateResult> recentMetrics = [
                    SELECT AVG(Execution_Time__c) avgTime
                    FROM Performance_Metric__c
                    WHERE Operation_Type__c = :threshold.Metric_Type__c
                    AND Timestamp__c >= :oneHourAgo
                ];
                if (!recentMetrics.isEmpty()) {
                    Decimal avgTime = (Decimal) recentMetrics[0].get('avgTime');
                    if (avgTime != null && avgTime > threshold.Threshold_Value__c) {
                        Map<String, Object> alert = new Map<String, Object>();
                        alert.put('metricType', threshold.Metric_Type__c);
                        alert.put('currentValue', avgTime);
                        alert.put('threshold', threshold.Threshold_Value__c);
                        alert.put('severity', threshold.Severity__c);
                        alert.put('message', threshold.Metric_Type__c + ' exceeds threshold: ' + String.valueOf(avgTime) + ' > ' + String.valueOf(threshold.Threshold_Value__c));
                        alert.put('timestamp', DateTime.now());
                        activeAlerts.add(alert);
                    }
                }
            }

            alerts.put('success', true);
            alerts.put('alerts', activeAlerts);
            alerts.put('alertCount', activeAlerts.size());
            alerts.put('checkTime', DateTime.now());
        } catch (Exception e) {
            alerts.put('success', false);
            alerts.put('error', e.getMessage());
        }
        return alerts;
    }

    // --------------------
    // HELPER METHODS
    // --------------------
    private static Decimal calculateUsagePercentage(Integer current, Integer maxLimit) {
        if (maxLimit == 0) return 0;
        return (Decimal.valueOf(current) / Decimal.valueOf(maxLimit)) * 100;
    }

    private static String calculateOverallHealth(Map<String, Decimal> usagePercentages) {
        Decimal maxUsage = 0;
        for (Decimal usage : usagePercentages.values()) {
            if (usage > maxUsage) maxUsage = usage;
        }
        if (maxUsage >= 90) return 'CRITICAL';
        if (maxUsage >= 75) return 'WARNING';
        if (maxUsage >= 50) return 'CAUTION';
        return 'HEALTHY';
    }

    private static String getPerformanceGrade(Map<String, Decimal> usagePercentages) {
        Decimal avgUsage = 0;
        Integer count = 0;
        for (Decimal usage : usagePercentages.values()) {
            avgUsage += usage;
            count++;
        }
        if (count == 0) return 'A';
        avgUsage = avgUsage / count;
        if (avgUsage >= 80) return 'D';
        if (avgUsage >= 60) return 'C';
        if (avgUsage >= 40) return 'B';
        return 'A';
    }

    private static List<String> generatePerformanceRecommendations(Map<String, Decimal> usagePercentages) {
        List<String> recommendations = new List<String>();
        if (usagePercentages.get('soqlUsage') != null && usagePercentages.get('soqlUsage') > 75) {
            recommendations.add('Optimize SOQL queries - usage at ' + usagePercentages.get('soqlUsage').setScale(1) + '%');
        }
        if (usagePercentages.get('cpuUsage') != null && usagePercentages.get('cpuUsage') > 75) {
            recommendations.add('Optimize CPU-intensive operations - usage at ' + usagePercentages.get('cpuUsage').setScale(1) + '%');
        }
        if (usagePercentages.get('heapUsage') != null && usagePercentages.get('heapUsage') > 75) {
            recommendations.add('Optimize memory usage - heap at ' + usagePercentages.get('heapUsage').setScale(1) + '%');
        }
        if (usagePercentages.get('dmlUsage') != null && usagePercentages.get('dmlUsage') > 75) {
            recommendations.add('Optimize DML operations - usage at ' + usagePercentages.get('dmlUsage').setScale(1) + '%');
        }
        if (recommendations.isEmpty()) {
            recommendations.add('System performance is optimal');
        }
        return recommendations;
    }

    private static List<String> generateBottleneckRecommendations(List<Map<String, Object>> issues) {
        List<String> recommendations = new List<String>();
        Map<String, Integer> issueTypes = new Map<String, Integer>();
        for (Map<String, Object> issue : issues) {
            String type = (String) issue.get('type');
            issueTypes.put(type, issueTypes.containsKey(type) ? issueTypes.get(type) + 1 : 1);
        }
        if (issueTypes.containsKey('SLOW_OPERATION')) {
            recommendations.add('Focus on optimizing slow operations - ' + issueTypes.get('SLOW_OPERATION') + ' identified');
        }
        if (issueTypes.containsKey('HIGH_RESOURCE_USAGE')) {
            recommendations.add('Review resource-intensive operations - ' + issueTypes.get('HIGH_RESOURCE_USAGE') + ' identified');
        }
        if (recommendations.isEmpty()) {
            recommendations.add('No significant bottlenecks identified');
        }
        return recommendations;
    }

    // --------------------
    // REPORT GENERATORS
    // --------------------
    private static Map<String, Object> generateExecutiveSummary(DateTime startDate) {
        Map<String, Object> summary = new Map<String, Object>();
        try {
            List<AggregateResult> overallStats = [
                SELECT COUNT(Id) totalOperations, AVG(Execution_Time__c) avgExecutionTime, MAX(Execution_Time__c) maxExecutionTime, AVG(CPU_Time_Used__c) avgCpuTime
                FROM Performance_Metric__c
                WHERE Timestamp__c >= :startDate
            ];
            if (!overallStats.isEmpty()) {
                AggregateResult stats = overallStats[0];
                summary.put('totalOperations', stats.get('totalOperations'));
                summary.put('averageExecutionTime', stats.get('avgExecutionTime'));
                summary.put('maxExecutionTime', stats.get('maxExecutionTime'));
                summary.put('averageCpuTime', stats.get('avgCpuTime'));
            }

            List<AggregateResult> dailyTrends = [
                SELECT DAY_ONLY(Timestamp__c) day, COUNT(Id) operations, AVG(Execution_Time__c) avgTime
                FROM Performance_Metric__c
                WHERE Timestamp__c >= :startDate
                GROUP BY DAY_ONLY(Timestamp__c)
                ORDER BY DAY_ONLY(Timestamp__c)
            ];
            summary.put('dailyTrends', dailyTrends);
            summary.put('reportType', 'EXECUTIVE_SUMMARY');
        } catch (Exception e) {
            summary.put('error', e.getMessage());
        }
        return summary;
    }

    private static Map<String, Object> generateDetailedAnalysis(DateTime startDate) {
        Map<String, Object> analysis = new Map<String, Object>();
        try {
            List<AggregateResult> operationBreakdown = [
                SELECT Operation_Type__c, COUNT(Id) operations, AVG(Execution_Time__c) avgTime, AVG(Queries_Used__c) avgQueries, AVG(CPU_Time_Used__c) avgCpu
                FROM Performance_Metric__c
                WHERE Timestamp__c >= :startDate
                GROUP BY Operation_Type__c
                ORDER BY COUNT(Id) DESC
            ];
            analysis.put('operationBreakdown', operationBreakdown);

            List<AggregateResult> hourlyPatterns = [
                SELECT HOUR_IN_DAY(Timestamp__c) hour, COUNT(Id) operations, AVG(Execution_Time__c) avgTime
                FROM Performance_Metric__c
                WHERE Timestamp__c >= :startDate
                GROUP BY HOUR_IN_DAY(Timestamp__c)
                ORDER BY HOUR_IN_DAY(Timestamp__c)
            ];
            analysis.put('hourlyPatterns', hourlyPatterns);
            analysis.put('reportType', 'DETAILED_ANALYSIS');
        } catch (Exception e) {
            analysis.put('error', e.getMessage());
        }
        return analysis;
    }

    private static Map<String, Object> generateBottleneckAnalysis(DateTime startDate) {
        // Reuse the logic used in identifyPerformanceBottlenecks but scoped to the given startDate
        Map<String, Object> analysis = new Map<String, Object>();
        try {
            List<Map<String, Object>> issues = new List<Map<String, Object>>();

            // Slow operations (avg execution time > 5s)
            List<AggregateResult> slowOperations = [
                SELECT Operation_Type__c, AVG(Execution_Time__c) avgTime, COUNT(Id) operationCount
                FROM Performance_Metric__c
                WHERE Timestamp__c >= :startDate
                GROUP BY Operation_Type__c
                HAVING AVG(Execution_Time__c) > 5000
                ORDER BY AVG(Execution_Time__c) DESC
            ];
            for (AggregateResult slowOp : slowOperations) {
                Map<String, Object> issue = new Map<String, Object>();
                issue.put('type', 'SLOW_OPERATION');
                issue.put('operationType', slowOp.get('Operation_Type__c'));
                issue.put('averageTime', slowOp.get('avgTime'));
                issue.put('operationCount', slowOp.get('operationCount'));
                issue.put('severity', 'HIGH');
                issue.put('recommendation', 'Optimize ' + String.valueOf(slowOp.get('Operation_Type__c')) + ' operations');
                issues.add(issue);
            }

            analysis.put('success', true);
            analysis.put('issues', issues);
            analysis.put('totalIssues', issues.size());
            analysis.put('generatedAt', DateTime.now());
        } catch (Exception e) {
            analysis.put('success', false);
            analysis.put('error', e.getMessage());
        }
        return analysis;
    }

    // --------------------
    // TIMEFRAME PARSER
    // --------------------
    // Accepts simple timeframe strings:
    // Examples: "24h", "1h", "7d", "30d", "90d", or a plain integer (days)
    private static DateTime calculateTimeframe(String timeframe) {
        if (String.isBlank(timeframe)) {
            // default to last 7 days
            return DateTime.now().addDays(-7);
        }

        String tf = timeframe.trim().toLowerCase();
        try {
            if (tf.endsWith('h')) {
                Integer hours = Integer.valueOf(tf.substring(0, tf.length() - 1));
                return DateTime.now().addHours(-hours);
            } else if (tf.endsWith('d')) {
                Integer days = Integer.valueOf(tf.substring(0, tf.length() - 1));
                return DateTime.now().addDays(-days);
            } else {
                // treat as days
                Integer days = Integer.valueOf(tf);
                return DateTime.now().addDays(-days);
            }
        } catch (Exception ex) {
            // fallback to last 7 days
            return DateTime.now().addDays(-7);
        }
    }
}