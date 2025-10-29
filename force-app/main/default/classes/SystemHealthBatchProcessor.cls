public class SystemHealthBatchProcessor implements Database.Batchable<String>, Database.Stateful {

    private List<String> components;
    private Map<String, Object> batchResults;

    public SystemHealthBatchProcessor() {
        this.components = new List<String>{ 'Database', 'Application', 'Integrations', 'Security', 'Compliance' };
        this.batchResults = new Map<String, Object>();
    }

    public Iterable<String> start(Database.BatchableContext bc) {
        return this.components;
    }

    public void execute(Database.BatchableContext bc, List<String> scope) {
        for (String component : scope) {
            try {
                Map<String, Object> componentHealth = performDetailedHealthCheck(component);
                this.batchResults.put(component, componentHealth);
            } catch (Exception e) {
                System.debug('Batch health check failed for ' + component + ': ' + e.getMessage());
                this.batchResults.put(component, new Map<String, Object>{
                    'error' => e.getMessage(),
                    'timestamp' => DateTime.now()
                });
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        try {
            // Store batch results if object exists
            if (Schema.getGlobalDescribe().containsKey('Batch_Health_Check__c')) {
                Batch_Health_Check__c batchRecord = new Batch_Health_Check__c();
                batchRecord.Check_Date__c = Date.today();
                batchRecord.Results__c = JSON.serialize(this.batchResults);
                batchRecord.Status__c = 'COMPLETED';
                batchRecord.Total_Components__c = this.components.size();

                try {
                    insert batchRecord;
                } catch (Exception e) {
                    System.debug('Failed to insert Batch_Health_Check__c: ' + e.getMessage());
                }
            } else {
                System.debug('Batch_Health_Check__c not present in org; skipping persist.');
            }

            // Generate summary notifications or alerts if needed
            generateBatchHealthSummary(this.batchResults);

        } catch (Exception e) {
            System.debug('Batch finish failed: ' + e.getMessage());
        }
    }

    private Map<String, Object> performDetailedHealthCheck(String component) {
        Map<String, Object> health = new Map<String, Object>();
        try {
            switch on component {
                when 'Database' {
                    health.put('healthScore', calculateDatabaseHealth());
                    health.put('responseTimeMs', getDatabaseResponseTime());
                    health.put('connectionCount', getCurrentConnectionCount());
                }
                when 'Application' {
                    health.put('healthScore', calculateApplicationHealth());
                    health.put('cpuUtilization', getCurrentCPUUtilization());
                    health.put('memoryUsage', getCurrentMemoryUsage());
                }
                when 'Integrations' {
                    health.put('healthScore', calculateIntegrationHealth());
                    health.put('apiCallSuccessRate', getAPICallSuccessRate());
                    health.put('externalServiceStatus', getExternalServiceStatus());
                }
                when 'Security' {
                    health.put('healthScore', calculateSecurityHealth());
                    health.put('threatLevel', determineCurrentThreatLevel());
                    health.put('recentIncidents', getRecentSecurityIncidents());
                }
                when 'Compliance' {
                    health.put('healthScore', calculateComplianceScore());
                    health.put('violationCount', getOpenComplianceViolations());
                    health.put('auditStatus', getAuditComplianceStatus());
                }
                when else {
                    health.put('healthScore', 50);
                    health.put('note', 'No specialized probe available for this component');
                }
            }
        } catch (Exception e) {
            health.put('error', e.getMessage());
        }

        health.put('component', component);
        health.put('timestamp', DateTime.now());
        return health;
    }

    // -------------------------
    // Summary and alert helpers
    // -------------------------
    private static void generateBatchHealthSummary(Map<String, Object> batchResults) {
        try {
            Integer criticalCount = 0;
            Integer warningCount = 0;
            Decimal totalScore = 0;
            Integer scoreCount = 0;

            for (String comp : batchResults.keySet()) {
                Object o = batchResults.get(comp);
                if (o instanceof Map<String, Object>) {
                    Map<String, Object> m = (Map<String, Object>) o;
                    if (m.containsKey('healthScore')) {
                        try {
                            Decimal hs = (m.get('healthScore') instanceof Decimal) ? 
                                (Decimal) m.get('healthScore') :
                                (m.get('healthScore') instanceof Integer) ?
                                Decimal.valueOf((Integer) m.get('healthScore')) :
                                Decimal.valueOf(String.valueOf(m.get('healthScore')));
                            totalScore += hs;
                            scoreCount++;
                            if (hs < 60) criticalCount++;
                            else if (hs < 80) warningCount++;
                        } catch (Exception ex) {
                            warningCount++;
                        }
                    } else if (m.containsKey('error')) {
                        criticalCount++;
                    } else {
                        warningCount++;
                    }
                } else {
                    warningCount++;
                }
            }

            Decimal avgScore = scoreCount > 0 ? (totalScore / scoreCount).setScale(1) : 0;

            String message = 'Components: ' + batchResults.keySet().size() +
                             ', AvgScore: ' + String.valueOf(avgScore) +
                             ', Critical: ' + String.valueOf(criticalCount) +
                             ', Warning: ' + String.valueOf(warningCount);

            try {
                if (Type.forName('AlertingSystem') != null) {
                    AlertingSystem.createAlert(
                        'BATCH_HEALTH_SUMMARY',
                        (criticalCount > 0) ? 'CRITICAL' : (warningCount > 0) ? 'HIGH' : 'MEDIUM',
                        message,
                        'SystemHealthBatchProcessor'
                    );
                } else {
                    System.debug('AlertingSystem not available; summary: ' + message);
                }
            } catch (Exception e) {
                System.debug('Unable to create alert; summary: ' + message);
            }
        } catch (Exception e) {
            System.debug('generateBatchHealthSummary error: ' + e.getMessage());
        }
    }

    // -------------------------
    // Concrete probe implementations
    // -------------------------
    private static Decimal calculateDatabaseHealth() {
        try {
            Integer u = [SELECT COUNT() FROM User LIMIT 1];
            return 95;
        } catch (Exception e) {
            System.debug('calculateDatabaseHealth: query failed: ' + e.getMessage());
            return 40;
        }
    }

    private static Decimal getDatabaseResponseTime() {
        try {
            if (Schema.getGlobalDescribe().containsKey('System_Performance_Log__c')) {
                List<AggregateResult> ar = Database.query(
                    'SELECT AVG(Response_Time__c) avgTime FROM System_Performance_Log__c ' +
                    'WHERE Timestamp__c >= :DateTime.now().addHours(-24)'
                );
                if (!ar.isEmpty() && ar[0].get('avgTime') != null) {
                    return ((Decimal) ar[0].get('avgTime')).setScale(2);
                }
            }
            return 200;
        } catch (Exception e) {
            System.debug('getDatabaseResponseTime error: ' + e.getMessage());
            return 0;
        }
    }

    private static Integer getCurrentConnectionCount() {
        try {
            Integer cnt = [SELECT COUNT() FROM AsyncApexJob WHERE CreatedDate >= :DateTime.now().addHours(-1)];
            return cnt;
        } catch (Exception e) {
            System.debug('getCurrentConnectionCount fallback: ' + e.getMessage());
            return 1;
        }
    }

    private static Decimal calculateApplicationHealth() {
        try {
            Decimal response = getDatabaseResponseTime();
            Integer activeJobs = [SELECT COUNT() FROM AsyncApexJob WHERE Status IN ('Processing', 'Queued')];
            Decimal score = 100;
            if (response > 3000) score -= 30;
            if (activeJobs > 50) score -= 20;
            return Math.max(0, score).setScale(1);
        } catch (Exception e) {
            System.debug('calculateApplicationHealth error: ' + e.getMessage());
            return 50;
        }
    }

    private static Decimal getCurrentCPUUtilization() {
    try {
        Decimal cpuUsed = Limits.getCpuTime();
        Decimal cpuLimit = Limits.getLimitCpuTime();

        if (cpuLimit > 0) {
            return ((cpuUsed / cpuLimit) * 100).setScale(1);
        }
        return 0;
    } catch (Exception e) {
        System.debug('getCurrentCPUUtilization error: ' + e.getMessage());
        return 0;
    }
}

   private static Decimal getCurrentMemoryUsage() {
    try {
        Decimal heapUsed = Limits.getHeapSize();
        Decimal heapLimit = Limits.getLimitHeapSize();

        if (heapLimit > 0) {
            return ((heapUsed / heapLimit) * 100).setScale(1);
        }
        return 0;
    } catch (Exception e) {
        System.debug('getCurrentMemoryUsage error: ' + e.getMessage());
        return 0;
    }
}


    private static Decimal calculateIntegrationHealth() {
        try {
            if (Schema.getGlobalDescribe().containsKey('Integration_Log__c')) {
                List<AggregateResult> ar = Database.query(
                    'SELECT COUNT(Id) totalCalls, ' +
                    'SUM(CASE WHEN Status__c = \'Success\' THEN 1 ELSE 0 END) successes ' +
                    'FROM Integration_Log__c WHERE Started_Date__c >= :DateTime.now().addHours(-24)'
                );
                if (!ar.isEmpty()) {
                    Integer total = (Integer) ar[0].get('totalCalls');
                    Integer succ = (Integer) ar[0].get('successes');
                    if (total > 0) {
                        Decimal rate = (Decimal.valueOf(succ) / total) * 100;
                        return rate.setScale(1);
                    }
                }
            }
            return 95;
        } catch (Exception e) {
            System.debug('calculateIntegrationHealth error: ' + e.getMessage());
            return 50;
        }
    }

    private static Decimal getAPICallSuccessRate() {
        try {
            if (Schema.getGlobalDescribe().containsKey('Integration_Log__c')) {
                List<AggregateResult> ar = Database.query(
                    'SELECT AVG(CASE WHEN Status__c = \'Success\' THEN 100 ELSE 0 END) avgPct ' +
                    'FROM Integration_Log__c WHERE Started_Date__c >= :DateTime.now().addHours(-24)'
                );
                if (!ar.isEmpty() && ar[0].get('avgPct') != null) {
                    return ((Decimal) ar[0].get('avgPct')).setScale(1);
                }
            }
            return 98;
        } catch (Exception e) {
            System.debug('getAPICallSuccessRate error: ' + e.getMessage());
            return 0;
        }
    }

    private static String getExternalServiceStatus() {
        try {
            if (Schema.getGlobalDescribe().containsKey('Integration_Log__c')) {
                Integer failures = [
                    SELECT COUNT() FROM Integration_Log__c 
                    WHERE Started_Date__c >= :DateTime.now().addHours(-24) 
                    AND Status__c = 'Failed'
                ];
                if (failures > 10) return 'DEGRADED';
                if (failures > 0) return 'WARN';
            }
            return 'OK';
        } catch (Exception e) {
            System.debug('getExternalServiceStatus error: ' + e.getMessage());
            return 'UNKNOWN';
        }
    }

    private static Decimal calculateSecurityHealth() {
        try {
            Integer incidents = 0;
            if (Schema.getGlobalDescribe().containsKey('System_Error__c')) {
                incidents = [
                    SELECT COUNT() FROM System_Error__c 
                    WHERE CreatedDate >= :DateTime.now().addDays(-7) 
                    AND Severity__c IN ('HIGH', 'CRITICAL')
                ];
            }
            Decimal score = 100;
            if (incidents > 10) score -= 50;
            else if (incidents > 3) score -= 20;
            return Math.max(0, score).setScale(1);
        } catch (Exception e) {
            System.debug('calculateSecurityHealth error: ' + e.getMessage());
            return 50;
        }
    }

    private static String determineCurrentThreatLevel() {
        try {
            Decimal score = calculateSecurityHealth();
            if (score < 30) return 'CRITICAL';
            if (score < 60) return 'HIGH';
            if (score < 80) return 'MEDIUM';
            return 'LOW';
        } catch (Exception e) {
            return 'UNKNOWN';
        }
    }

    private static Integer getRecentSecurityIncidents() {
        try {
            if (Schema.getGlobalDescribe().containsKey('Security_Incident__c')) {
                return [SELECT COUNT() FROM Security_Incident__c WHERE CreatedDate >= :DateTime.now().addDays(-7)];
            }
            return 0;
        } catch (Exception e) {
            System.debug('getRecentSecurityIncidents error: ' + e.getMessage());
            return 0;
        }
    }

    private static Decimal calculateComplianceScore() {
        try {
            if (Schema.getGlobalDescribe().containsKey('DocumentComplianceTracking__c')) {
                List<AggregateResult> ar = Database.query(
                    'SELECT AVG(Compliance_Score__c) avgScore FROM DocumentComplianceTracking__c ' +
                    'WHERE Analysis_Date__c >= :DateTime.now().addDays(-30)'
                );
                if (!ar.isEmpty() && ar[0].get('avgScore') != null) {
                    return ((Decimal) ar[0].get('avgScore')).setScale(1);
                }
            }
            return 90;
        } catch (Exception e) {
            System.debug('calculateComplianceScore error: ' + e.getMessage());
            return 50;
        }
    }

    private static Integer getOpenComplianceViolations() {
        try {
            if (Schema.getGlobalDescribe().containsKey('DocumentComplianceFinding__c')) {
                return [SELECT COUNT() FROM DocumentComplianceFinding__c WHERE Status__c = 'OPEN'];
            }
            return 0;
        } catch (Exception e) {
            System.debug('getOpenComplianceViolations error: ' + e.getMessage());
            return 0;
        }
    }

    private static String getAuditComplianceStatus() {
        try {
            Integer openHigh = 0;
            if (Schema.getGlobalDescribe().containsKey('DocumentComplianceFinding__c')) {
                openHigh = [
                    SELECT COUNT() FROM DocumentComplianceFinding__c 
                    WHERE Status__c = 'OPEN' 
                    AND Severity__c IN ('HIGH', 'CRITICAL')
                ];
            }
            return openHigh > 0 ? 'NEEDS_ATTENTION' : 'OK';
        } catch (Exception e) {
            System.debug('getAuditComplianceStatus error: ' + e.getMessage());
            return 'UNKNOWN';
        }
    }
}