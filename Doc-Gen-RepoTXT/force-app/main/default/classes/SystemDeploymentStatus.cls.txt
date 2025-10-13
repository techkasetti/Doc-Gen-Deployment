/**
 * Complete deployment validation and production readiness assessment
 */
public class SystemDeploymentStatus {

    @AuraEnabled(cacheable=false)
    public static String generateFinalDeploymentReport() {
        StringBuilder finalReport = new StringBuilder();

        try {
            finalReport.append('==========================================\n');
            finalReport.append(' FINAL DEPLOYMENT STATUS REPORT\n');
            finalReport.append('==========================================\n');
            finalReport.append('Generated: ' + DateTime.now().format('yyyy-MM-dd H'));
            finalReport.append('Generated: ' + DateTime.now().format());
            finalReport.append('\n\n');

            SystemHealthMonitor.HealthMetrics healthMetrics = SystemHealthMonitor.getCurrentHealthMetrics();
            ProductionReadinessChecker.ChecklistResult readinessResult = ProductionReadinessChecker.executeProductionReadinessCheck();
            FinalSystemStatusReport.StatusReport statusReport = FinalSystemStatusReport.generateCompleteSystemReport();

            finalReport.append('DEPLOYMENT SUMMARY\n');
            finalReport.append('Overall Health Score: ' + statusReport.systemHealthScore + '%\n');
            finalReport.append('System Status: ' + statusReport.overallStatus + '\n');
            finalReport.append('Production Ready: ' + (readinessResult.readyForProduction ? 'YES' : 'NO') + '\n');
            finalReport.append('Completion Rate: ' + readinessResult.completionPercentage + '%\n');

            finalReport.append('\nCORE COMPONENTS STATUS\n');
            for (FinalSystemStatusReport.ComponentReport component : statusReport.componentReports) {
                finalReport.append(
                    component.componentName + ': ' + component.status + 
                    ' (' + component.healthScore + '%)\n'
                );
            }

            finalReport.append('\nSYSTEM METRICS\n');
            finalReport.append('Total Documents: ' + statusReport.systemMetrics.get('totalDocuments') + '\n');
            finalReport.append('Active Templates: ' + statusReport.systemMetrics.get('activeTemplates') + '\n');
            finalReport.append('Monthly Transactions: ' + statusReport.systemMetrics.get('monthlyTransactions') + '\n');
            finalReport.append('Compliance Score: ' + statusReport.systemMetrics.get('complianceScore') + '\n');

            finalReport.append('\nCRITICAL ISSUES\n');
            if (readinessResult.criticalIssues.isEmpty()) {
                finalReport.append('No critical issues detected\n');
            } else {
                for (String issue : readinessResult.criticalIssues) {
                    finalReport.append('- ' + issue + '\n');
                }
            }

            finalReport.append('\nRECOMMENDATIONS\n');
            for (String recommendation : statusReport.recommendations) {
                finalReport.append('- ' + recommendation + '\n');
            }

        } catch (Exception e) {
            finalReport.append('ERROR: ' + e.getMessage());
        }

        return finalReport.toString();
    }

    @AuraEnabled(cacheable=false)
    public static Map<String, Object> getDeploymentMetrics() {
        Map<String, Object> metrics = new Map<String, Object>();

        try {
            FinalSystemStatusReport.StatusReport report = FinalSystemStatusReport.generateCompleteSystemReport();
            ProductionReadinessChecker.ChecklistResult readiness = ProductionReadinessChecker.executeProductionReadinessCheck();

            metrics.put('overallHealthScore', report.systemHealthScore);
            metrics.put('systemStatus', report.overallStatus);
            metrics.put('productionReady', readiness.readyForProduction);
            metrics.put('completionPercentage', readiness.completionPercentage);
            metrics.put('completedItems', readiness.completedItems);
            metrics.put('totalItems', readiness.totalItems);
            metrics.put('criticalIssuesCount', readiness.criticalIssues.size());
            metrics.put('componentCount', report.componentReports.size());

            Integer operationalComponents = 0;
            for (FinalSystemStatusReport.ComponentReport component : report.componentReports) {
                if (component.healthScore >= 80) {
                    operationalComponents++;
                }
            }
            metrics.put('operationalComponents', operationalComponents);

            metrics.put('systemMetrics', report.systemMetrics);
            metrics.put('keyFindings', report.keyFindings);
            metrics.put('recommendations', report.recommendations);

        } catch (Exception e) {
            metrics.put('error', e.getMessage());
        }

        return metrics;
    }

    @AuraEnabled(cacheable=false)
    public static Boolean validateSystemReadiness() {
        try {
            ProductionReadinessChecker.ChecklistResult result = ProductionReadinessChecker.executeProductionReadinessCheck();
            FinalSystemStatusReport.StatusReport statusReport = FinalSystemStatusReport.generateCompleteSystemReport();

            Boolean healthScoreAcceptable = statusReport.systemHealthScore >= 85;
            Boolean completionAcceptable = result.completionPercentage >= 90;
            Boolean noCriticalIssues = result.criticalIssues.isEmpty();

            return healthScoreAcceptable && completionAcceptable && noCriticalIssues;

        } catch (Exception e) {
            System.debug('System readiness validation failed: ' + e.getMessage());
            return false;
        }
    }
}
