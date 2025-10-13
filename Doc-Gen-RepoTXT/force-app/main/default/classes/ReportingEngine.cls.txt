/**
 * @description Essential Performance Monitor - Core performance monitoring only
 */
public with sharing class PerformanceMonitor {

    // -------------------- CORE PERFORMANCE --------------------

    @AuraEnabled
    public static Map<String, Object> getSystemPerformance() {
        Map<String, Object> performance = new Map<String, Object>();
        try {
            // Governor limits
            Map<String, Object> limits = new Map<String, Object>();
            limits.put('soqlQueries', Limits.getQueries() + '/' + Limits.getLimitQueries());
            limits.put('soqlRows', Limits.getQueryRows() + '/' + Limits.getLimitQueryRows());
            limits.put('dmlStatements', Limits.getDMLStatements() + '/' + Limits.getLimitDMLStatements());
            limits.put('dmlRows', Limits.getDMLRows() + '/' + Limits.getLimitDMLRows());
            limits.put('cpuTime', Limits.getCpuTime() + '/' + Limits.getLimitCpuTime());
            limits.put('heapSize', Limits.getHeapSize() + '/' + Limits.getLimitHeapSize());

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
            performance.put('governorLimits', limits);
            performance.put('usagePercentages', usagePercentages);
            performance.put('healthIndicators', healthIndicators);
            performance.put('timestamp', DateTime.now());

        } catch (Exception e) {
            performance.put('success', false);
            performance.put('error', e.getMessage());
        }
        return performance;
    }

    // -------------------- OPERATION PERFORMANCE --------------------

    @AuraEnabled
    public static Map<String, Object> measureOperationPerformance(String operationType, String operationId) {
        Map<String, Object> result = new Map<String, Object>();
        Long startTime = System.currentTimeMillis();

        try {
            // Record initial resource usage
            Integer initialQueries = Limits.getQueries();
            Integer initialCpuTime = Limits.getCpuTime();
            Integer initialHeapSize = Limits.getHeapSize();

            // Simulate operation measurement (to be replaced with actual operations)
            Thread.sleep(100); // Simulate processing time

            // Calculate resource consumption
            Long executionTime = System.currentTimeMillis() - startTime;
            Integer queriesUsed = Limits.getQueries() - initialQueries;
            Integer cpuUsed = Limits.getCpuTime() - initialCpuTime;
            Integer heapUsed = Limits.getHeapSize() - initialHeapSize;

            // Create performance record
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

    // -------------------- PERFORMANCE TRENDS --------------------

    @AuraEnabled
    public static Map<String, Object> getPerformanceTrends(String timeframe, String metricType) {
        Map<String, Object> trends = new Map<String, Object>();
        try {
            DateTime startDate = calculateTimeframe(timeframe);
            String query = 
                'SELECT AVG(Execution_Time__c) avgTime, AVG(Queries_Used__c) avgQueries, ' +
                'AVG(CPU_Time_Used__c) avgCpu, COUNT(Id) operationCount, ' +
                'CALENDAR_HOUR(Timestamp__c) hour ' +
                'FROM Performance_Metric__c WHERE Timestamp__c >= :startDate';

            if (String.isNotBlank(metricType)) {
                query += ' AND Operation_Type__c = :metricType';
            }

            query += ' GROUP BY CALENDAR_HOUR(Timestamp__c) ORDER BY CALENDAR_HOUR(Timestamp__c)';
            List<AggregateResult> trendData = Database.query(query);

            List<Map<String, Object>> hourlyTrends = new List<Map<String, Object>>();
            for (AggregateResult trend : trendData) {
                Map<String, Object> hourlyData = new Map<String, Object>();
                hourlyData.put('hour', trend.get('hour'));
                hourlyData.put('averageTime', trend.get('avgTime'));
                hourlyData.put('averageQueries', trend.get('avgQueries'));
                hourlyData.put('averageCpu', trend.get('avgCpu'));
                hourlyData.put('operationCount', trend.get('operationCount'));
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

    // -------------------- BOTTLENECKS --------------------

    @AuraEnabled
    public static Map<String, Object> identifyPerformanceBottlenecks() {
        Map<String, Object> bottlenecks = new Map<String, Object>();
        try {
            List<Map<String, Object>> issues = new List<Map<String, Object>>();

            // Slow operations
            List<AggregateResult> slowOperations = [
                SELECT Operation_Type__c, AVG(Execution_Time__c) avgTime, COUNT(Id) operationCount
                FROM Performance_Metric__c
                WHERE Timestamp__c >= :DateTime.now().addHours(-24)
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
                issue.put('recommendation', 'Optimize ' + slowOp.get('Operation_Type__c') + ' operations');
                issues.add(issue);
            }

            // High resource usage operations
            List<AggregateResult> resourceHeavyOps = [
                SELECT Operation_Type__c, AVG(CPU_Time_Used__c) avgCpu, AVG(Queries_Used__c) avgQueries
                FROM Performance_Metric__c
                WHERE Timestamp__c >= :DateTime.now().addHours(-24)
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
                issue.put('recommendation', 'Review resource usage for ' + heavyOp.get('Operation_Type__c'));
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
    
    // -------------------- REPORTS --------------------
    // (EXECUTIVE_SUMMARY, DETAILED_ANALYSIS, BOTTLENECK_ANALYSIS methods stay the same, just formatted)

    // -------------------- UTILITIES --------------------
    private static Decimal calculateUsagePercentage(Integer current, Integer maxLimit) {
    if (maxLimit == 0) return 0;
    return (Decimal.valueOf(current) / Decimal.valueOf(maxLimit)) * 100;
}


    private static String calculateOverallHealth(Map<String, Decimal> usagePercentages) {
        Decimal maxUsage = 0;
        for (Decimal usage : usagePercentages.values()) {
            if (usage > maxUsage) {
                maxUsage = usage;
            }
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
        avgUsage = avgUsage / count;
        if (avgUsage >= 80) return 'D';
        if (avgUsage >= 60) return 'C';
        if (avgUsage >= 40) return 'B';
        return 'A';
    }

    // -------------------- CUSTOM EXCEPTION --------------------
    public class PerformanceException extends Exception {}
}
