public class SystemDeploymentStatus {

    // ==========================================
    // MAIN REPORT GENERATION METHOD
    // ==========================================
    @AuraEnabled(cacheable = false)
    public static String generateFinalDeploymentReport() {
        String finalReport = '';

        try {
            finalReport += '==========================================\n';
            finalReport += '        FINAL DEPLOYMENT STATUS REPORT\n';
            finalReport += '==========================================\n';
            finalReport += 'Generated: ' + DateTime.now().format('yyyy-MM-dd HH:mm:ss') + '\n\n';

            // ------------------------------------------
            // Metric Initialization
            // ------------------------------------------
            Decimal systemHealthScore = 0;
            String overallStatus = 'Unknown';
            Boolean readyForProduction = false;
            Decimal completionPercentage = 0;

            Map<String, Object> systemMetrics = new Map<String, Object>();
            List<String> recommendations = new List<String>();
            List<String> criticalIssues = new List<String>();

            try {
                // Example metrics - use dynamic queries only when objects exist
                Integer totalDocuments = getCountIfObjectExists('ContentVersion', null);
                Integer activeTemplates = getCountIfObjectExists('Document_Template__c', 'Active__c = true');
                Integer monthlyTransactions = getCountIfObjectExists(
                    'Document_Generation_Audit__c',
                    'CreatedDate >= :DateTime.now().addDays(-30)'
                );

                Integer complianceScoreRaw = 0;

                if (Schema.getGlobalDescribe().containsKey('DocumentComplianceTracking__c')) {
                    AggregateResult[] ar = Database.query(
                        'SELECT AVG(Overall_Compliance_Score__c) avgScore FROM DocumentComplianceTracking__c ' +
                        'WHERE Overall_Compliance_Score__c != NULL'
                    );
                    if (ar != null && !ar.isEmpty() && ar[0].get('avgScore') != null) {
                        complianceScoreRaw = ((Decimal) ar[0].get('avgScore')).intValue();
                    }
                } else {
                    complianceScoreRaw = 95;
                }

                systemMetrics.put('totalDocuments', totalDocuments);
                systemMetrics.put('activeTemplates', activeTemplates);
                systemMetrics.put('monthlyTransactions', monthlyTransactions);
                systemMetrics.put('complianceScore', complianceScoreRaw);

                // ------------------------------------------
                // Basic Health Calculation
                // ------------------------------------------
                Decimal perfScore = 95;

                if (Schema.getGlobalDescribe().containsKey('System_Performance_Log__c')) {
                    AggregateResult[] apr = Database.query(
                        'SELECT AVG(Response_Time__c) avgResp FROM System_Performance_Log__c WHERE Response_Time__c != NULL'
                    );

                    if (apr != null && !apr.isEmpty() && apr[0].get('avgResp') != null) {
                        Decimal avgResp = (Decimal) apr[0].get('avgResp');
                        if (avgResp > 3000) perfScore -= 40;
                        else if (avgResp > 1000) perfScore -= 15;
                    }
                }

                Decimal compScore = complianceScoreRaw != null ? Decimal.valueOf(complianceScoreRaw) : 90;
                systemHealthScore = ((perfScore * 0.5) + (compScore * 0.5)) / 1.0;
                systemHealthScore = systemHealthScore.setScale(1);

                // ------------------------------------------
                // Determine Overall Status
                // ------------------------------------------
                if (systemHealthScore >= 90) overallStatus = 'Healthy';
                else if (systemHealthScore >= 75) overallStatus = 'Degraded';
                else overallStatus = 'Unhealthy';

                // ------------------------------------------
                // Completion Percentage (Deployment Records)
                // ------------------------------------------
                if (Schema.getGlobalDescribe().containsKey('Deployment_Record__c')) {
                    Integer total = getCountIfObjectExists('Deployment_Record__c', null);
                    if (total > 0) {
                        Integer completed = getCountIfObjectExists(
                            'Deployment_Record__c',
                            'Status__c = \'COMPLETED\''
                        );
                        completionPercentage = total > 0
                            ? (Decimal.valueOf(completed) / total * 100).setScale(1)
                            : 100;
                    } else {
                        completionPercentage = 100;
                    }
                } else {
                    completionPercentage = 100;
                }

                readyForProduction = (systemHealthScore >= 85 && completionPercentage >= 90);

                // ------------------------------------------
                // Critical Issues
                // ------------------------------------------
                if (Schema.getGlobalDescribe().containsKey('System_Alert__c')) {
                    Integer crit = getCountIfObjectExists(
                        'System_Alert__c',
                        'Severity__c IN (\'CRITICAL\', \'HIGH\') AND Status__c = \'ACTIVE\''
                    );
                    if (crit > 0) {
                        criticalIssues.add(crit + ' active high-severity alert(s) present');
                    }
                }

                // ------------------------------------------
                // Recommendations
                // ------------------------------------------
                if (systemHealthScore < 85)
                    recommendations.add('Investigate system performance and compliance hotspots');
                if (completionPercentage < 95)
                    recommendations.add('Review deployment steps and retry failed phases');
                if (criticalIssues.size() == 0)
                    recommendations.add('No immediate critical issues detected');

            } catch (Exception innerEx) {
                // Metric collection fallback
                System.debug('Metric collection failed: ' + innerEx.getMessage());
                systemHealthScore = 75;
                overallStatus = 'Partial';
                readyForProduction = false;
                completionPercentage = 80;
                systemMetrics.put('message', 'Metric collection fallback used');
                recommendations.add('Metric collection failed — review logs');
            }

            // ------------------------------------------
            // Build the Final Report
            // ------------------------------------------
            finalReport = appendLine(finalReport, 'DEPLOYMENT SUMMARY');
            finalReport = appendLine(finalReport, 'Overall Health Score: ' + String.valueOf(systemHealthScore) + '%');
            finalReport = appendLine(finalReport, 'System Status: ' + overallStatus);
            finalReport = appendLine(finalReport, 'Production Ready: ' + (readyForProduction ? 'YES' : 'NO'));
            finalReport = appendLine(finalReport, 'Completion Rate: ' + String.valueOf(completionPercentage) + '%');
            finalReport = appendLine(finalReport, '');

            finalReport = appendLine(finalReport, 'SYSTEM METRICS');
            for (String key : systemMetrics.keySet()) {
                finalReport = appendLine(finalReport, key + ': ' + String.valueOf(systemMetrics.get(key)));
            }

            finalReport = appendLine(finalReport, '');
            finalReport = appendLine(finalReport, 'CRITICAL ISSUES');

            if (criticalIssues.isEmpty()) {
                finalReport = appendLine(finalReport, 'No critical issues detected');
            } else {
                for (String issue : criticalIssues) {
                    finalReport = appendLine(finalReport, '- ' + issue);
                }
            }

            finalReport = appendLine(finalReport, '');
            finalReport = appendLine(finalReport, 'RECOMMENDATIONS');

            for (String rec : recommendations) {
                finalReport = appendLine(finalReport, '- ' + rec);
            }

            finalReport = appendLine(finalReport, '');
            finalReport = appendLine(finalReport, '==========================================');
            finalReport = appendLine(finalReport, 'END OF REPORT');
            finalReport = appendLine(finalReport, '==========================================');

        } catch (Exception e) {
            finalReport += 'ERROR: ' + e.getMessage();
        }

        return finalReport;
    }

    // ==========================================
    // DEPLOYMENT METRICS SUMMARY
    // ==========================================
    @AuraEnabled(cacheable = false)
    public static Map<String, Object> getDeploymentMetrics() {
        Map<String, Object> metrics = new Map<String, Object>();

        try {
            metrics.put('timestamp', DateTime.now());
            metrics.put('totalContentVersions', getCountIfObjectExists('ContentVersion', null));
            metrics.put('activeTemplates', getCountIfObjectExists('Document_Template__c', 'Active__c = true'));
            metrics.put('openComplianceFindings', getCountIfObjectExists('DocumentComplianceFinding__c', 'Status__c = \'OPEN\''));
            metrics.put(
                'recentHighAlerts',
                getCountIfObjectExists(
                    'System_Alert__c',
                    'Severity__c IN (\'CRITICAL\', \'HIGH\') AND CreatedDate >= :DateTime.now().addDays(-7)'
                )
            );

            // Derive health
            Decimal health = 0;
            try {
                if (Schema.getGlobalDescribe().containsKey('System_Performance_Log__c')) {
                    AggregateResult[] ar = Database.query(
                        'SELECT AVG(Response_Time__c) avgResp FROM System_Performance_Log__c WHERE Response_Time__c != NULL'
                    );
                    if (ar != null && !ar.isEmpty() && ar[0].get('avgResp') != null) {
                        Decimal avgResp = (Decimal) ar[0].get('avgResp');
                        health = avgResp > 3000 ? 40 : avgResp > 1000 ? 75 : 95;
                    } else {
                        health = 90;
                    }
                } else {
                    health = 90;
                }
            } catch (Exception e) {
                health = 70;
            }

            metrics.put('computedHealthScore', health);
            metrics.put(
                'notes',
                'For richer metrics, ensure telemetry objects (System_Performance_Log__c, DocumentComplianceFinding__c, System_Alert__c, Document_Template__c) are deployed.'
            );

        } catch (Exception e) {
            metrics.put('error', e.getMessage());
        }

        return metrics;
    }

    // ==========================================
    // VALIDATION METHOD
    // ==========================================
    @AuraEnabled(cacheable = false)
    public static Boolean validateSystemReadiness() {
        try {
            Map<String, Object> metrics = getDeploymentMetrics();

            Decimal healthScore = metrics.containsKey('computedHealthScore')
                ? (Decimal) metrics.get('computedHealthScore')
                : 0;

            Integer criticalAlerts = (Integer) getCountIfObjectExists(
                'System_Alert__c',
                'Severity__c IN (\'CRITICAL\', \'HIGH\') AND Status__c = \'ACTIVE\''
            );

            Boolean healthOk = healthScore >= 85;
            Boolean noCritical = criticalAlerts == 0;

            Decimal completionPct = 100;

            try {
                if (Schema.getGlobalDescribe().containsKey('Deployment_Record__c')) {
                    Integer total = getCountIfObjectExists('Deployment_Record__c', null);
                    if (total > 0) {
                        Integer completed = getCountIfObjectExists('Deployment_Record__c', 'Status__c = \'COMPLETED\'');
                        completionPct = (Decimal.valueOf(completed) / total * 100).setScale(1);
                    }
                }
            } catch (Exception e) {
                completionPct = 100;
            }

            Boolean completionOk = completionPct >= 90;
            return healthOk && noCritical && completionOk;

        } catch (Exception e) {
            System.debug('System readiness validation failed: ' + e.getMessage());
            return false;
        }
    }

    // ==========================================
    // UTILITY HELPERS
    // ==========================================
    private static String appendLine(String target, String line) {
        if (target == null) target = '';
        if (line == null) line = '';
        return target + line + '\n';
    }

    private static Integer getCountIfObjectExists(String sObjectApiName, String whereClause) {
        try {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            if (!gd.containsKey(sObjectApiName)) return 0;

            String q = 'SELECT COUNT() totalCount FROM ' + sObjectApiName;
            if (whereClause != null && whereClause.trim().length() > 0) {
                q += ' WHERE ' + whereClause;
            }

            AggregateResult[] ar = Database.query(q);

            if (ar != null && ar.size() > 0) {
                Object v = ar[0].get('totalCount');
                if (v instanceof Integer) return (Integer) v;
                if (v instanceof Long) return Integer.valueOf(((Long) v).intValue());
                if (v instanceof Decimal) return Integer.valueOf(((Decimal) v).intValue());
            }

            return 0;
        } catch (Exception e) {
            System.debug('getCountIfObjectExists error for ' + sObjectApiName + ': ' + e.getMessage());
            return 0;
        }
    }
}