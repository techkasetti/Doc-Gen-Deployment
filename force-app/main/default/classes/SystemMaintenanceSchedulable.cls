public class SystemMaintenanceSchedulable implements Schedulable {

    public void execute(SchedulableContext sc) {
        try {
            // Execute maintenance tasks
            List<String> maintenanceResults = new List<String>();
            
            // Clean up old logs
            Integer cleanedLogs = cleanupOldLogs();
            maintenanceResults.add('Cleaned up ' + cleanedLogs + ' old log records');
            
            // Optimize system performance
            Boolean optimizationResult = optimizeSystemPerformance();
            maintenanceResults.add('System optimization: ' + (optimizationResult ? 'SUCCESS' : 'PARTIAL'));
            
            // Validate data integrity
            Map<String, Integer> integrityResults = validateDataIntegrity();
            maintenanceResults.add('Data integrity validation completed');
            
            // Update system statistics
            updateSystemStatistics();
            maintenanceResults.add('System statistics updated');
            
            // Log maintenance execution
            System_Maintenance_Log__c maintenanceLog = new System_Maintenance_Log__c(
                Maintenance_Type__c = 'SCHEDULED_MAINTENANCE',
                Maintenance_Date__c = DateTime.now(),
                Status__c = 'COMPLETED',
                Results__c = String.join(maintenanceResults, '; '),
                Records_Processed__c = cleanedLogs,
                Duration_Minutes__c = calculateMaintenanceDuration(),
                Performed_By__c = 'SYSTEM'
            );
            insert maintenanceLog;
            
        } catch (Exception e) {
            // Log maintenance failure
            System_Maintenance_Log__c errorLog = new System_Maintenance_Log__c(
                Maintenance_Type__c = 'SCHEDULED_MAINTENANCE',
                Maintenance_Date__c = DateTime.now(),
                Status__c = 'FAILED',
                Results__c = 'Maintenance failed: ' + e.getMessage(),
                Error_Details__c = e.getStackTraceString(),
                Performed_By__c = 'SYSTEM'
            );
            insert errorLog;
        }
    }

    private Integer cleanupOldLogs() {
        try {
            DateTime cutoffDate = DateTime.now().addDays(-90); // Keep 90 days of logs
            
            List<System_Error_Log__c> oldErrorLogs = [
                SELECT Id 
                FROM System_Error_Log__c 
                WHERE CreatedDate < :cutoffDate 
                LIMIT 10000
            ];
            
            if (!oldErrorLogs.isEmpty()) {
                delete oldErrorLogs;
            }
            
            return oldErrorLogs.size();
        } catch (Exception e) {
            System.debug('Log cleanup failed: ' + e.getMessage());
            return 0;
        }
    }

      private Boolean optimizeSystemPerformance() {
        try {
            // Clear platform cache if utilization is high
            if (Cache.Org.contains('high_utilization_flag')) {
                Cache.Org.remove('high_utilization_flag');
            }
            
            // Update performance statistics
            Performance_Statistics__c stats = Performance_Statistics__c.getOrgDefaults();
            if (stats == null) {
                stats = new Performance_Statistics__c(
                    SetupOwnerId = UserInfo.getOrganizationId()
                );
            }
            
            stats.Last_Optimization__c = DateTime.now();
            stats.Cache_Cleared__c = true;
            stats.Optimization_Count__c = (stats.Optimization_Count__c ?? 0) + 1;
            
            upsert stats;
            
            return true;
        } catch (Exception e) {
            System.debug('Performance optimization failed: ' + e.getMessage());
            return false;
        }
    }

        // Validate data integrity and analyze system health trends
    private Map<String, Object> validateDataIntegrity() {
        Map<String, Object> trends = new Map<String, Object>();
        
        try {
            // === Data Integrity Checks ===
            
            // 1. Orphaned AuditTrail records (referencing inactive or missing users)
            Integer orphanedAuditTrails = [
                SELECT COUNT() 
                FROM AuditTrail__c 
                WHERE UserId__c NOT IN (
                    SELECT Id FROM User WHERE IsActive = true
                )
            ];
            trends.put('orphanedAuditTrails', orphanedAuditTrails);
            
            // 2. Incomplete monitoring logs older than 24 hours
            Integer incompleteMonitoringLogs = [
                SELECT COUNT() 
                FROM System_Monitoring_Log__c 
                WHERE Status__c = 'IN_PROGRESS' 
                AND Execution_Time__c < :DateTime.now().addHours(-24)
            ];
            trends.put('incompleteMonitoringLogs', incompleteMonitoringLogs);
            
            // 3. Duplicate alerts created today
            List<AggregateResult> duplicateAlerts = [
                SELECT Alert_Type__c, Message__c, COUNT(Id) duplicateCount
                FROM System_Alert__c 
                WHERE CreatedDate = TODAY
                GROUP BY Alert_Type__c, Message__c
                HAVING COUNT(Id) > 1
            ];
            trends.put('duplicateAlerts', duplicateAlerts.size());
            
            
            // === Trend Analysis ===
            Date sevenDaysAgo = Date.today().addDays(-7);
            
            // Alert trends by day and severity
            List<AggregateResult> alertTrends = [
                SELECT DAY_ONLY(Triggered_At__c) alertDay,
                    Severity__c,
                    COUNT(Id) alertCount
                FROM System_Alert__c
                WHERE Triggered_At__c >= :sevenDaysAgo
                GROUP BY DAY_ONLY(Triggered_At__c), Severity__c
                ORDER BY DAY_ONLY(Triggered_At__c)
            ];
            
            Map<String, Map<String, Integer>> alertData = new Map<String, Map<String, Integer>>();
            for (AggregateResult trend : alertTrends) {
                String dayKey = String.valueOf(trend.get('alertDay'));
                String severity = (String)trend.get('Severity__c');
                Integer count = (Integer)trend.get('alertCount');
                
                if (!alertData.containsKey(dayKey)) {
                    alertData.put(dayKey, new Map<String, Integer>());
                }
                alertData.get(dayKey).put(severity, count);
            }
            trends.put('alertTrends', alertData);
            
            
            // Usage trends by day (FIXED with COUNT_DISTINCT)
            List<AggregateResult> usageTrends = [
                SELECT DAY_ONLY(Timestamp__c) usageDay,
                    COUNT(Id) totalOperations,
                    COUNT_DISTINCT(UserId__c) uniqueUsers
                FROM AuditTrail__c
                WHERE Timestamp__c >= :sevenDaysAgo
                GROUP BY DAY_ONLY(Timestamp__c)
                ORDER BY DAY_ONLY(Timestamp__c)
            ];
            
            List<Map<String, Object>> usageData = new List<Map<String, Object>>();
            for (AggregateResult usage : usageTrends) {
                Map<String, Object> dayUsage = new Map<String, Object>();
                dayUsage.put('date', usage.get('usageDay'));
                dayUsage.put('totalOperations', usage.get('totalOperations'));
                dayUsage.put('uniqueUsers', usage.get('uniqueUsers'));
                usageData.add(dayUsage);
            }
            trends.put('usageData', usageData);
            
        } catch (Exception e) {
            trends.put('error', 'Unable to retrieve system health trends: ' + e.getMessage());
        }
        
        return trends;
    }

    // Alert management methods
        @AuraEnabled
        public static Map<String, Object> acknowledgeAlert(Id alertId, String acknowledgedBy) {
            Map<String, Object> result = new Map<String, Object>();
            try {
                System_Alert__c alert = [
                    SELECT Id, Status__c, Acknowledged_By__c, Acknowledged_At__c
                    FROM System_Alert__c
                    WHERE Id = :alertId
                    LIMIT 1
                ];

                alert.Status__c = 'ACKNOWLEDGED';
                alert.Acknowledged_By__c = acknowledgedBy;
                alert.Acknowledged_At__c = DateTime.now();
                update alert;

                // Log acknowledgment
                AuditTrail__c auditLog = new AuditTrail__c(
                    Action__c = 'ALERT_ACKNOWLEDGED',
                    Details__c = 'Alert acknowledged: ' + alertId,
                    UserId__c = UserInfo.getUserId(),
                    Timestamp__c = DateTime.now(),
                    Status__c = 'SUCCESS',
                    RelatedRecordId__c = alertId
                );
                insert auditLog;

                result.put('success', true);
                result.put('message', 'Alert acknowledged successfully');

            } catch (Exception e) {
                result.put('success', false);
                result.put('error', e.getMessage());
            }
            return result;
        }


        @AuraEnabled
    public static Map<String, Object> dismissAlert(Id alertId, String dismissalReason) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            System_Alert__c alert = [
                SELECT Id, Status__c
                FROM System_Alert__c
                WHERE Id = :alertId
                LIMIT 1
            ];

            alert.Status__c = 'DISMISSED';
            alert.Dismissal_Reason__c = dismissalReason;
            alert.Dismissed_At__c = DateTime.now();
            alert.Dismissed_By__c = UserInfo.getUserId();
            update alert;

            // Log dismissal
            AuditTrail__c auditLog = new AuditTrail__c(
                Action__c = 'ALERT_DISMISSED',
                Details__c = 'Alert dismissed: ' + alertId + '. Reason: ' + dismissalReason,
                UserId__c = UserInfo.getUserId(),
                Timestamp__c = DateTime.now(),
                Status__c = 'SUCCESS',
                RelatedRecordId__c = alertId
            );
            insert auditLog;

            result.put('success', true);
            result.put('message', 'Alert dismissed successfully');

        } catch (Exception e) {
            result.put('success', false);
            result.put('error', e.getMessage());
        }
        return result;
    }

    @AuraEnabled
    public static Map<String, Object> resolveAlert(Id alertId, String resolutionNotes) {
        Map<String, Object> result = new Map<String, Object>();
        try {
            System_Alert__c alert = [
                SELECT Id, Status__c
                FROM System_Alert__c
                WHERE Id = :alertId
                LIMIT 1
            ];

            alert.Status__c = 'RESOLVED';
            alert.Resolution_Notes__c = resolutionNotes;
            alert.Resolved_At__c = DateTime.now();
            alert.Resolved_By__c = UserInfo.getUserId();
            update alert;

            // Log resolution
            AuditTrail__c auditLog = new AuditTrail__c(
                Action__c = 'ALERT_RESOLVED',
                Details__c = 'Alert resolved: ' + alertId + '. Notes: ' + resolutionNotes,
                UserId__c = UserInfo.getUserId(),
                Timestamp__c = DateTime.now(),
                Status__c = 'SUCCESS',
                RelatedRecordId__c = alertId
            );
            insert auditLog;

            result.put('success', true);
            result.put('message', 'Alert resolved successfully');

        } catch (Exception e) {
            result.put('success', false);
            result.put('error', e.getMessage());
        }
        return result;
    }

        // Report generation methods
        @AuraEnabled
        public static Map<String, Object> generateSystemHealthReport(String timeframe, String format) {
            Map<String, Object> result = new Map<String, Object>();
            try {
                DateTime startDate = calculateStartDate(timeframe);
                Map<String, Object> reportData = generateComprehensiveHealthReport(startDate);

                String reportContent = '';
                String fileName = '';
                String contentType = '';

                switch on format.toUpperCase() {
                    when 'PDF' {
                        reportContent = generatePDFReport(reportData);
                        fileName = 'SystemHealthReport_' + DateTime.now().format('yyyyMMdd_HHmm') + '.pdf';
                        contentType = 'application/pdf';
                    }
                    when 'CSV' {
                        reportContent = generateCSVReport(reportData);
                        fileName = 'SystemHealthReport_' + DateTime.now().format('yyyyMMdd_HHmm') + '.csv';
                        contentType = 'text/csv';
                    }
                    when 'JSON' {
                        reportContent = JSON.serialize(reportData);
                        fileName = 'SystemHealthReport_' + DateTime.now().format('yyyyMMdd_HHmm') + '.json';
                        contentType = 'application/json';
                    }
                    when else {
                        throw new AuraHandledException('Unsupported format: ' + format);
                    }
                }

                // Store report record
                System_Report__c reportRecord = new System_Report__c(
                    Report_Type__c = 'SYSTEM_HEALTH',
                    Report_Format__c = format,
                    Generated_By__c = UserInfo.getUserId(),
                    Generated_At__c = DateTime.now(),
                    Report_Period__c = timeframe,
                    File_Name__c = fileName,
                    Content_Type__c = contentType,
                    Report_Size__c = reportContent.length()
                );
                insert reportRecord;

                result.put('success', true);
                result.put('reportId', reportRecord.Id);
                result.put('fileName', fileName);
                result.put('content', reportContent);
                result.put('contentType', contentType);

            } catch (Exception e) {
                result.put('success', false);
                result.put('error', e.getMessage());
            }
            return result;
        }

        
        
        private static Map<String, Object> generateComprehensiveHealthReport(DateTime startDate) {
            Map<String, Object> reportData = new Map<String, Object>();

            // Report metadata
            reportData.put('reportTitle', 'System Health Comprehensive Report');
            reportData.put('generatedAt', DateTime.now());
            reportData.put('reportPeriod', startDate.format() + ' to ' + DateTime.now().format());
            reportData.put('generatedBy', UserInfo.getName());

            // Executive summary
            Map<String, Object> executiveSummary = generateExecutiveHealthSummary();
            reportData.put('executiveSummary', executiveSummary);

            // Performance metrics
            Map<String, Object> performanceReport = generatePerformanceReport(startDate);
            reportData.put('performanceMetrics', performanceReport);

            // Security analysis
            Map<String, Object> securityReport = generateSecurityReport(startDate);
            reportData.put('securityAnalysis', securityReport);

            // Alert summary
            Map<String, Object> alertReport = generateAlertReport(startDate);
            reportData.put('alertSummary', alertReport);

            // Trend analysis
            Map<String, Object> trendReport = generateTrendReport(startDate);
            reportData.put('trendAnalysis', trendReport);

            // Recommendations
            List<String> recommendations = generateHealthRecommendations(executiveSummary, performanceReport);
            reportData.put('recommendations', recommendations);

            return reportData;
        }

        private static String generatePDFReport(Map<String, Object> reportData) {
            // In a real implementation, this would use a PDF generation library
            // For now, return formatted text that could be converted to PDF
            StringBuilder pdfContent = new StringBuilder();

            pdfContent.append('SYSTEM HEALTH REPORT\n');
            pdfContent.append('====================\n\n');
            pdfContent.append('Generated: ' + reportData.get('generatedAt') + '\n');
            pdfContent.append('Period: ' + reportData.get('reportPeriod') + '\n');
            pdfContent.append('Generated By: ' + reportData.get('generatedBy') + '\n\n');

            // Executive Summary
            Map<String, Object> execSummary = (Map<String, Object>)reportData.get('executiveSummary');
            if (execSummary != null) {
                pdfContent.append('EXECUTIVE SUMMARY\n');
                pdfContent.append('=================\n');
                pdfContent.append('Overall Health Score: ' + execSummary.get('overallHealthScore') + '\n');
                pdfContent.append('System Status: ' + execSummary.get('systemStatus') + '\n');
                pdfContent.append('Critical Issues: ' + execSummary.get('criticalIssues') + '\n\n');
            }

            // Performance Metrics
            Map<String, Object> performance = (Map<String, Object>)reportData.get('performanceMetrics');
            if (performance != null) {
                pdfContent.append('PERFORMANCE METRICS\n');
                pdfContent.append('===================\n');
                pdfContent.append('Average Response Time: ' + performance.get('averageResponseTime') + 'ms\n');
                pdfContent.append('Error Rate: ' + performance.get('errorRate') + '%\n');
                pdfContent.append('System Uptime: ' + performance.get('uptime') + '%\n\n');
            }

            return pdfContent.toString();
        }

        private static String generateCSVReport(Map<String, Object> reportData) {
            StringBuilder csvContent = new StringBuilder();

            // CSV Header
            csvContent.append('Metric,Value,Unit,Status,Timestamp\n');

            // Add executive summary data
            Map<String, Object> execSummary = (Map<String, Object>)reportData.get('executiveSummary');
            if (execSummary != null) {
                csvContent.append('Overall Health Score,' + execSummary.get('overallHealthScore') + ',Points,');
                csvContent.append(execSummary.get('systemStatus') + ',' + DateTime.now().format() + '\n');
            }

            // Add performance data
            Map<String, Object> performance = (Map<String, Object>)reportData.get('performanceMetrics');
            if (performance != null) {
                csvContent.append('Average Response Time,' + performance.get('averageResponseTime') + ',Milliseconds,');
                csvContent.append('NORMAL,' + DateTime.now().format() + '\n');
                csvContent.append('Error Rate,' + performance.get('errorRate') + ',Percentage,');
                csvContent.append('NORMAL,' + DateTime.now().format() + '\n');
            }

            return csvContent.toString();
        }

        private static Map<String, Object> generatePerformanceReport(DateTime startDate) {
            Map<String, Object> report = new Map<String, Object>();
            try {
                // Performance statistics
                List<AggregateResult> perfStats = [
                    SELECT AVG(Average_Response_Time__c) avgResponseTime,
                        MIN(Average_Response_Time__c) minResponseTime,
                        MAX(Average_Response_Time__c) maxResponseTime,
                        AVG(Error_Rate__c) avgErrorRate,
                        COUNT(Id) totalSnapshots
                    FROM Performance_Snapshot__c
                    WHERE Snapshot_Time__c >= :startDate
                ];

                if (!perfStats.isEmpty()) {
                    AggregateResult stats = perfStats[0];
                    report.put('averageResponseTime', stats.get('avgResponseTime'));
                    report.put('minResponseTime', stats.get('minResponseTime'));
                    report.put('maxResponseTime', stats.get('maxResponseTime'));
                    report.put('averageErrorRate', stats.get('avgErrorRate'));
                    report.put('totalMeasurements', stats.get('totalSnapshots'));
                }

                // Performance grade
                Decimal avgResponseTime = (Decimal)report.get('averageResponseTime');
                Decimal avgErrorRate = (Decimal)report.get('averageErrorRate');
                String performanceGrade = calculatePerformanceGrade(avgResponseTime, avgErrorRate);
                report.put('performanceGrade', performanceGrade);

                // Uptime calculation
                Decimal uptime = calculateSystemUptime();
                report.put('uptime', uptime);

            } catch (Exception e) {
                report.put('error', 'Performance report generation failed: ' + e.getMessage());
            }
            return report;
        }

            // Generate a security report summarizing incidents and login failures
        private static Map<String, Object> generateSecurityReport(DateTime startDate) {
            Map<String, Object> report = new Map<String, Object>();
            
            try {
                // === Security Incidents ===
                Integer securityIncidents = [
                    SELECT COUNT()
                    FROM Security_Event_Log__c
                    WHERE Event_Date__c >= :startDate.date()
                    AND Severity__c IN ('CRITICAL', 'HIGH')
                ];
                report.put('securityIncidents', securityIncidents);

                // === Failed Login Attempts ===
                Integer failedLogins = [
                    SELECT COUNT()
                    FROM LoginHistory
                    WHERE LoginTime >= :startDate
                    AND Status = 'F'
                ];
                report.put('failedLogins', failedLogins);

                // === Compliance Score (placeholder for calculation) ===
                // You likely need logic or another query here
                Decimal complianceScore = 100; // Example static value for now
                report.put('complianceScore', complianceScore);

            } catch (Exception e) {
                report.put('error', 'Failed to generate security report: ' + e.getMessage());
            }
            
            return report;
        }


        // ================================
        // Event Publishing Utilities
        // ================================

        // Publish health status events
        public static void publishHealthStatusEvent(Map<String, Object> healthData) {
            try {
                Health_Status_Event__e healthEvent = new Health_Status_Event__e(
                    Response_Time__c   = (Decimal)healthData.get('responseTime'),
                    Error_Rate__c      = (Decimal)healthData.get('errorRate'),
                    Active_Users__c    = (Integer)healthData.get('activeUsers'),
                    Timestamp__c       = DateTime.now(),
                    Event_Source__c    = 'HEALTH_MONITOR',
                    Alert_Level__c     = (String)healthData.get('alertLevel'),
                    Component__c       = (String)healthData.get('component'),
                    Details__c         = (String)healthData.get('details')
                );

                EventBus.publish(healthEvent);
                System.debug('Health status event published successfully');
            } catch (Exception e) {
                System.debug('Failed to publish health status event: ' + e.getMessage());
            }
        }


        // Publish performance alerts
        public static void publishPerformanceEvent(Map<String, Object> performanceData) {
            try {
                Performance_Alert_Event__e perfEvent = new Performance_Alert_Event__e(
                    Metric_Type__c     = (String)performanceData.get('metricType'),
                    Current_Value__c   = (Decimal)performanceData.get('currentValue'),
                    Threshold_Value__c = (Decimal)performanceData.get('threshold'),
                    Severity__c        = (String)performanceData.get('severity'),
                    Component_Name__c  = (String)performanceData.get('component'),
                    Timestamp__c       = DateTime.now(),
                    Alert_Message__c   = (String)performanceData.get('message'),
                    Requires_Action__c = (Boolean)performanceData.get('requiresAction')
                );

                EventBus.publish(perfEvent);
                System.debug('Performance event published successfully');
            } catch (Exception e) {
                System.debug('Failed to publish performance event: ' + e.getMessage());
            }
        }

        // =========================
    // Risk Assessment Methods
    // =========================
    private static Map<String, Object> assessPerformanceRisk() {
        Map<String, Object> risk = new Map<String, Object>();
        try {
            Decimal avgResponseTime = getRecentAverageResponseTime();
            Decimal errorRate = getCurrentErrorRate();

            String riskLevel = 'LOW';
            Integer riskScore = 0;
            List<String> riskFactors = new List<String>();

            // Response time risk assessment
            if (avgResponseTime > 5000) {
                riskLevel = 'CRITICAL';
                riskScore += 40;
                riskFactors.add('Critical response time degradation detected');
            } else if (avgResponseTime > 3000) {
                riskLevel = 'HIGH';
                riskScore += 25;
                riskFactors.add('Elevated response times affecting user experience');
            } else if (avgResponseTime > 2000) {
                if (riskLevel == 'LOW') riskLevel = 'MEDIUM';
                riskScore += 15;
                riskFactors.add('Response times approaching warning threshold');
            }

            // Error rate risk assessment
            if (errorRate > 10) {
                riskLevel = 'CRITICAL';
                riskScore += 50;
                riskFactors.add('Critical error rate detected - system stability at risk');
            } else if (errorRate > 5) {
                if (riskLevel != 'CRITICAL') riskLevel = 'HIGH';
                riskScore += 30;
                riskFactors.add('High error rate impacting system reliability');
            } else if (errorRate > 2) {
                if (riskLevel == 'LOW') riskLevel = 'MEDIUM';
                riskScore += 15;
                riskFactors.add('Error rate trending upward');
            }

            // Final output
            risk.put('category', 'PERFORMANCE');
            risk.put('level', riskLevel);
            risk.put('score', riskScore);
            risk.put('riskFactors', riskFactors);

        } catch (Exception e) {
            risk.put('error', 'Performance risk assessment failed: ' + e.getMessage());
        }
        return risk;
    }

    private static Map<String, Object> assessSecurityRisk() {
        Map<String, Object> risk = new Map<String, Object>();
        try {
            Integer securityIncidents = getRecentSecurityIncidents();
            Integer failedLogins = getRecentFailedLogins();

            String riskLevel = 'LOW';
            Integer riskScore = 0;
            List<String> riskFactors = new List<String>();

            // Security incidents assessment
            if (securityIncidents > 10) {
                riskLevel = 'CRITICAL';
                riskScore += 60;
                riskFactors.add('Multiple critical security incidents detected');
            } else if (securityIncidents > 5) {
                riskLevel = 'HIGH';
                riskScore += 35;
                riskFactors.add('Elevated security incident activity');
            } else if (securityIncidents > 0) {
                riskLevel = 'MEDIUM';
                riskScore += 15;
                riskFactors.add('Security incidents require monitoring');
            }

            // Failed login assessment
            if (failedLogins > 1000) {
                riskLevel = 'CRITICAL';
                riskScore += 40;
                riskFactors.add('Excessive failed login attempts - potential brute force attack');
            } else if (failedLogins > 500) {
                if (riskLevel != 'CRITICAL') riskLevel = 'HIGH';
                riskScore += 25;
                riskFactors.add('High number of failed login attempts');
            } else if (failedLogins > 100) {
                if (riskLevel == 'LOW') riskLevel = 'MEDIUM';
                riskScore += 10;
                riskFactors.add('Elevated failed login activity');
            }

            // Final output
            risk.put('category', 'SECURITY');
            risk.put('level', riskLevel);
            risk.put('score', riskScore);
            risk.put('riskFactors', riskFactors);

        } catch (Exception e) {
            risk.put('error', 'Security risk assessment failed: ' + e.getMessage());
        }
        return risk;
    }

    private static Map<String, Object> assessComplianceRisk() {
        Map<String, Object> risk = new Map<String, Object>();
        try {
            Decimal complianceScore = calculateComplianceScore();
            Integer openViolations = getOpenComplianceViolations();

            String riskLevel = 'LOW';
            Integer riskScore = 0;
            List<String> riskFactors = new List<String>();

            // Compliance score assessment
            if (complianceScore < 60) {
                riskLevel = 'CRITICAL';
                riskScore += 50;
                riskFactors.add('Critical compliance score requires immediate attention');
            } else if (complianceScore < 80) {
                riskLevel = 'HIGH';
                riskScore += 30;
                riskFactors.add('Compliance score below acceptable threshold');
            } else if (complianceScore < 90) {
                riskLevel = 'MEDIUM';
                riskScore += 15;
                riskFactors.add('Compliance improvements needed');
            }

            // Open violations assessment
            if (openViolations > 10) {
                riskLevel = 'CRITICAL';
                riskScore += 40;
                riskFactors.add('Multiple open compliance violations');
            } else if (openViolations > 5) {
                if (riskLevel != 'CRITICAL') riskLevel = 'HIGH';
                riskScore += 25;
                riskFactors.add('Several compliance violations pending resolution');
            } else if (openViolations > 0) {
                if (riskLevel == 'LOW') riskLevel = 'MEDIUM';
                riskScore += 10;
                riskFactors.add('Compliance violations require attention');
            }

            // Final output
            risk.put('category', 'COMPLIANCE');
            risk.put('level', riskLevel);
            risk.put('score', riskScore);
            risk.put('riskFactors', riskFactors);

        } catch (Exception e) {
            risk.put('error', 'Compliance risk assessment failed: ' + e.getMessage());
        }
        return risk;
    }

    private static Integer getOpenComplianceViolations() {
        try {
            return [
                SELECT COUNT()
                FROM Compliance_Violation__c
                WHERE Status__c = 'OPEN'
            ];
        } catch (Exception e) {
            return 0;
        }
    }

    
        private static Decimal calculateIntegrationHealth() {
        try {
            Decimal healthScore = 100;
            DateTime lastHour = DateTime.now().addHours(-1);

            // ✅ Query 1: Total calls + avg response time
            AggregateResult totalStats = [
                SELECT COUNT(Id) totalCalls, AVG(Response_Time_Ms__c) avgResponseTime
                FROM Integration_Log__c
                WHERE Call_Timestamp__c >= :lastHour
            ];

            // ✅ Query 2: Successful calls (status < 400)
            AggregateResult successStats = [
                SELECT COUNT(Id) successfulCalls
                FROM Integration_Log__c
                WHERE Call_Timestamp__c >= :lastHour
                AND Status_Code__c < 400
            ];

            Integer totalCalls = (totalStats != null && totalStats.get('totalCalls') != null)
                                ? (Integer) totalStats.get('totalCalls') : 0;

            Decimal avgResponseTime = (totalStats != null && totalStats.get('avgResponseTime') != null)
                                ? (Decimal) totalStats.get('avgResponseTime') : 0;

            Integer successfulCalls = (successStats != null && successStats.get('successfulCalls') != null)
                                ? (Integer) successStats.get('successfulCalls') : 0;

            // ✅ Calculate health score
            if (totalCalls > 0) {
                Decimal successRate = (Decimal.valueOf(successfulCalls) / totalCalls) * 100;

                if (successRate < 70) healthScore -= 40;
                else if (successRate < 85) healthScore -= 20;
                else if (successRate < 95) healthScore -= 10;
            }

            if (avgResponseTime > 10000) healthScore -= 25;
            else if (avgResponseTime > 5000) healthScore -= 15;
            else if (avgResponseTime > 3000) healthScore -= 5;

            return Math.max(0, healthScore);

        } catch (Exception e) {
            return 70; // Moderate default for integrations
        }
    }

        private static Decimal calculateSecurityHealth() {
            try {
                Decimal healthScore = 100;
                DateTime last24Hours = DateTime.now().addHours(-24);
                
                // Check security incidents
                Integer securityIncidents = getRecentSecurityIncidents();
                if (securityIncidents > 10) healthScore -= 50;
                else if (securityIncidents > 5) healthScore -= 30;
                else if (securityIncidents > 0) healthScore -= 10;
                
                // Check failed login attempts
                Integer failedLogins = getRecentFailedLogins();
                if (failedLogins > 1000) healthScore -= 30;
                else if (failedLogins > 500) healthScore -= 15;
                else if (failedLogins > 100) healthScore -= 5;
                
                // Check data access anomalies
                Integer dataAnomalies = [
                    SELECT COUNT()
                    FROM Data_Access_Log__c
                    WHERE Access_Date__c >= :last24Hours.date()
                    AND Anomaly_Score__c > 75
                ];
                
                if (dataAnomalies > 20) healthScore -= 25;
                else if (dataAnomalies > 10) healthScore -= 15;
                else if (dataAnomalies > 5) healthScore -= 5;
                
                return Math.max(0, healthScore);
            } catch (Exception e) {
                return 80; // Conservative security default
            }
        }

        private static Map<String, Object> getPerformanceMetricsSummary() {
        Map<String, Object> metrics = new Map<String, Object>();
        
        try {
            metrics.put('responseTime', getRecentAverageResponseTime());
            metrics.put('throughput', getCurrentThroughput());
            metrics.put('errorRate', getCurrentErrorRate());
            metrics.put('cacheHitRatio', calculateCacheHitRatio());
            metrics.put('cpuUtilization', (Decimal.valueOf(Limits.getCpuTime()) / Limits.getLimitCpuTime()) * 100);
            metrics.put('memoryUtilization', (Decimal.valueOf(Limits.getHeapSize()) / Limits.getLimitHeapSize()) * 100);
            metrics.put('databaseConnections', getCurrentConnectionPoolUtilization());
            metrics.put('lastUpdated', DateTime.now());
        } catch (Exception e) {
            metrics.put('error', 'Performance metrics collection failed: ' + e.getMessage());
        }
        
        return metrics;
    }

        private static Map<String, Object> getSecurityMetricsSummary() {
            Map<String, Object> metrics = new Map<String, Object>();
            
            try {
                DateTime last24Hours = DateTime.now().addHours(-24);
                
                metrics.put('securityIncidents', getRecentSecurityIncidents());
                metrics.put('failedLogins', getRecentFailedLogins());
                metrics.put('suspiciousActivities', getSuspiciousActivities());
                metrics.put('dataAccessAnomalies', getDataAccessAnomalies());
                metrics.put('complianceViolations', getOpenComplianceViolations());
                metrics.put('securityScore', calculateSecurityHealth());
                metrics.put('threatLevel', determineCurrentThreatLevel());
                metrics.put('lastSecurityScan', getLastSecurityScanDate());
                metrics.put('lastUpdated', DateTime.now());
            } catch (Exception e) {
                metrics.put('error', 'Security metrics collection failed: ' + e.getMessage());
            }
            
            return metrics;
        }
                
    private static Integer getSuspiciousActivities() {
        try {
            DateTime last24Hours = DateTime.now().addHours(-24);
            return [
                SELECT COUNT()
                FROM Suspicious_Activity_Log__c
                WHERE Activity_Timestamp__c >= :last24Hours
                AND Risk_Level__c IN ('HIGH', 'CRITICAL')
            ];
        } catch (Exception e) {
            return 0;
        }
    }

    private static Integer getDataAccessAnomalies() {
        try {
            DateTime last24Hours = DateTime.now().addHours(-24);
            return [
                SELECT COUNT()
                FROM Data_Access_Log__c
                WHERE Access_Date__c >= :last24Hours.date()
                AND Anomaly_Score__c > 70
            ];
        } catch (Exception e) {
            return 0;
        }
    }
        // Threat level determination
    private static String determineCurrentThreatLevel() {
        try {
            Integer securityIncidents = getRecentSecurityIncidents();
            Integer suspiciousActivities = getSuspiciousActivities();
            Integer failedLogins = getRecentFailedLogins();

            if (securityIncidents > 5 || suspiciousActivities > 20 || failedLogins > 500) {
                return 'HIGH';
            } else if (securityIncidents > 2 || suspiciousActivities > 10 || failedLogins > 200) {
                return 'MEDIUM';
            } else if (securityIncidents > 0 || suspiciousActivities > 5 || failedLogins > 50) {
                return 'LOW';
            }
            return 'MINIMAL';
        } catch (Exception e) {
            return 'UNKNOWN';
        }
    }

    // Last completed security scan date
    private static DateTime getLastSecurityScanDate() {
        try {
            List<Security_Scan_Log__c> lastScan = [
                SELECT Scan_Completed__c
                FROM Security_Scan_Log__c
                WHERE Scan_Status__c = 'COMPLETED'
                ORDER BY Scan_Completed__c DESC
                LIMIT 1
            ];

            return !lastScan.isEmpty()
                ? lastScan[0].Scan_Completed__c
                : DateTime.now().addDays(-30);

        } catch (Exception e) {
            return DateTime.now().addDays(-7);
        }
    }

    // Generate system health recommendations
    private static List<String> generateSystemHealthRecommendations(SystemHealthWrapper health) {
        List<String> recommendations = new List<String>();

        try {
            // Overall health recommendations
            if (health.overallHealthScore < 60) {
                recommendations.add('CRITICAL: System requires immediate attention - health score below 60%');
                recommendations.add('Execute emergency system recovery procedures');
                recommendations.add('Conduct comprehensive system audit');
            } else if (health.overallHealthScore < 80) {
                recommendations.add('WARNING: System performance degraded - implement corrective measures');
                recommendations.add('Review and address performance bottlenecks');
            }

            // Response time recommendations
            if (health.averageResponseTime > 5000) {
                recommendations.add('URGENT: Optimize system response times - currently exceeding 5 seconds');
                recommendations.add('Implement caching strategies and database optimization');
            } else if (health.averageResponseTime > 3000) {
                recommendations.add('Consider performance tuning to improve response times');
            }

            // Error rate recommendations
            if (health.errorRate > 10) {
                recommendations.add('CRITICAL: Address high error rate immediately');
                recommendations.add('Investigate and resolve underlying system issues');
            } else if (health.errorRate > 5) {
                recommendations.add('Monitor error patterns and implement preventive measures');
            }

            // Alert recommendations
            if (health.criticalAlerts > 0) {
                recommendations.add('IMMEDIATE: Resolve ' + health.criticalAlerts + ' critical alerts');
            }
            if (health.totalAlerts > 20) {
                recommendations.add('Review alert configuration to reduce notification noise');
            }

            // Compliance recommendations
            if (health.complianceScore < 85) {
                recommendations.add('COMPLIANCE: Strengthen compliance measures - score below 85%');
                recommendations.add('Conduct compliance training and policy review');
            }

            // Uptime recommendations
            if (health.systemUptime < 99) {
                recommendations.add('AVAILABILITY: Improve system reliability - uptime below 99%');
                recommendations.add('Implement high availability and disaster recovery measures');
            }

            // Component-specific recommendations
            for (ComponentHealthStatus component : health.componentHealth) {
                if (component.healthScore < 70) {
                    recommendations.add('COMPONENT: Address ' + component.componentName + ' health issues');
                }
            }

            // General operational recommendations
            if (recommendations.isEmpty()) {
                recommendations.add('MAINTAIN: System performance within acceptable parameters');
                recommendations.add('Continue regular monitoring and maintenance schedules');
            }

        } catch (Exception e) {
            recommendations.add('ERROR: Unable to generate complete recommendations - ' + e.getMessage());
        }

        return recommendations;
    }

    // Calculate health trend based on last 7 days
    private static String calculateHealthTrend() {
        try {
            DateTime sevenDaysAgo = DateTime.now().addDays(-7);

            List<AggregateResult> healthHistory = [
                SELECT DAY_ONLY(Check_Timestamp__c) checkDay,
                    AVG(Overall_Health_Score__c) avgHealthScore
                FROM System_Health_Check__c
                WHERE Check_Timestamp__c >= :sevenDaysAgo
                AND Overall_Health_Score__c != null
                GROUP BY DAY_ONLY(Check_Timestamp__c)
                ORDER BY DAY_ONLY(Check_Timestamp__c)
            ];

            if (healthHistory.size() < 3) {
                return 'INSUFFICIENT_DATA';
            }

            List<Decimal> scores = new List<Decimal>();
            for (AggregateResult result : healthHistory) {
                scores.add((Decimal)result.get('avgHealthScore'));
            }

            return calculateTrendDirection(scores);

        } catch (Exception e) {
            return 'UNKNOWN';
        }
    }

    // Utility methods

    // Simulated connection pool utilization
    private static Decimal getCurrentConnectionPoolUtilization() {
        try {
            // In real implementation, this would query actual database metrics
            return Math.random() * 50 + 30; // 30–80% utilization
        } catch (Exception e) {
            return 50; // Default moderate utilization
        }
    }

    // Current system throughput
    private static Integer getCurrentThroughput() {
        try {
            DateTime lastHour = DateTime.now().addHours(-1);

            return [
                SELECT COUNT()
                FROM AuditTrail__c
                WHERE Timestamp__c >= :lastHour
            ];

        } catch (Exception e) {
            return 0;
        }
    }


        // =============================
    // Batch Health Summary Generator
    // =============================
    private static void generateBatchHealthSummary(Map<String, Object> batchResults) {
        try {
            Integer criticalComponents = 0;
            Integer warningComponents = 0;
            Decimal totalHealthScore = 0;

            for (String component : batchResults.keySet()) {
                Map<String, Object> componentData = 
                    (Map<String, Object>) batchResults.get(component);

                Decimal healthScore = (Decimal) componentData.get('healthScore');
                totalHealthScore += healthScore;

                if (healthScore < 60) {
                    criticalComponents++;
                } else if (healthScore < 80) {
                    warningComponents++;
                }
            }

            Decimal averageHealth = totalHealthScore / batchResults.size();

            // Create system alert if needed
            if (criticalComponents > 0) {
                createSystemAlert(
                    'BATCH_HEALTH_CHECK_CRITICAL',
                    'CRITICAL',
                    criticalComponents + 
                    ' components in critical state. Average health: ' + 
                    averageHealth.setScale(1) + '%'
                );
            } else if (warningComponents > 2) {
                createSystemAlert(
                    'BATCH_HEALTH_CHECK_WARNING',
                    'WARNING',
                    warningComponents + 
                    ' components require attention. Average health: ' + 
                    averageHealth.setScale(1) + '%'
                );
            }
        } catch (Exception e) {
            System.debug('Batch summary generation failed: ' + e.getMessage());
        }
    }

    // =============================
    // Utility Methods for Health Checks
    // =============================

    private static Decimal getDatabaseResponseTime() {
        try {
            Long startTime = System.currentTimeMillis();
            [SELECT COUNT() FROM User LIMIT 1];
            Long endTime = System.currentTimeMillis();
            return Decimal.valueOf(endTime - startTime);
        } catch (Exception e) {
            return 1000; // Default 1 second
        }
    }

    private static Integer getCurrentConnectionCount() {
        try {
            // Simulate connection count - in real implementation would query actual metrics
            return Integer.valueOf(Math.random() * 50 + 10);
        } catch (Exception e) {
            return 25;
        }
    }

    private static Decimal getCurrentCPUUtilization() {
        return (Decimal.valueOf(Limits.getCpuTime()) / Limits.getLimitCpuTime()) * 100;
    }

    private static Decimal getCurrentMemoryUsage() {
        return (Decimal.valueOf(Limits.getHeapSize()) / Limits.getLimitHeapSize()) * 100;
    }

    private static Decimal getAPICallSuccessRate() {
        try {
            DateTime lastHour = DateTime.now().addHours(-1);

            // Query all calls in the last hour
            List<AggregateResult> totalStats = [
                SELECT COUNT(Id) totalCalls
                FROM Integration_Log__c
                WHERE Call_Timestamp__c >= :lastHour
            ];

            // Query only successful calls (< 400 status code)
            List<AggregateResult> successStats = [
                SELECT COUNT(Id) successCalls
                FROM Integration_Log__c
                WHERE Call_Timestamp__c >= :lastHour
                AND Status_Code__c < 400
            ];

            Integer total = (Integer) totalStats[0].get('totalCalls');
            Integer success = (Integer) successStats[0].get('successCalls');

            if (total > 0) {
                return (Decimal.valueOf(success) / total) * 100;
            }
            return 100; // Default: if no calls made, assume 100% success
        } catch (Exception e) {
            return 90; // Conservative default on error
        }
    }


    private static String getExternalServiceStatus() {
        try {
            // Check external service connectivity
            Integer failedServices = [
                SELECT COUNT()
                FROM External_Service_Status__c
                WHERE Status__c != 'OPERATIONAL'
                AND Last_Check__c >= :DateTime.now().addMinutes(-15)
            ];

            return failedServices == 0 ? 'ALL_OPERATIONAL' : 'SOME_ISSUES';
        } catch (Exception e) {
            return 'UNKNOWN';
        }
    }

    private static String getAuditComplianceStatus() {
        try {
            DateTime last7Days = DateTime.now().addDays(-7);
            Integer failedAudits = [
                SELECT COUNT()
                FROM Audit_Trail__c
                WHERE Timestamp__c >= :last7Days
                AND Status__c = 'COMPLIANCE_FAILED'
            ];

            return failedAudits == 0 ? 'COMPLIANT' : 'VIOLATIONS_DETECTED';
        } catch (Exception e) {
            return 'UNKNOWN';
        }
    }


    // =============================
    // System Health API
    // =============================
    @RestResource(urlMapping='/systemhealth/v1/*')
    global with sharing class SystemHealthAPI {
        
        @HttpGet
        global static Map<String, Object> getSystemHealthStatus() {
            try {
                String endpoint = RestContext.request.getRestResourcePath();

                if (endpoint.contains('/summary')) {
                    return getCurrentSystemHealthSummary();
                } else if (endpoint.contains('/detailed')) {
                    return getDetailedSystemHealth();
                } else if (endpoint.contains('/alerts')) {
                    return getActiveAlertsAPI();
                } else {
                    return getCurrentSystemStatus();
                }

            } catch (Exception e) {
                return new Map<String, Object>{
                    'status'    => 'ERROR',
                    'message'   => 'API request failed: ' + e.getMessage(),
                    'timestamp' => DateTime.now()
                };
            }
        }
    }

        // ==============================================
    // System Health Monitoring Utilities
    // ==============================================
    private static Map<String, Object> getCurrentSystemHealthSummary() {
        Map<String, Object> summary = new Map<String, Object>();
        
        Decimal overallHealth = calculateOverallHealthScore();
        
        summary.put('overallHealthScore', overallHealth);
        summary.put('systemStatus', calculateSystemStatus(overallHealth));
        summary.put('uptime', calculateSystemUptime());
        summary.put('responseTime', getRecentAverageResponseTime());
        summary.put('errorRate', getCurrentErrorRate());
        summary.put('timestamp', DateTime.now());
        summary.put('apiVersion', '1.0');
        
        return summary;
    }

    // ==============================================
    // Detailed Health
    // ==============================================
    private static Map<String, Object> getDetailedSystemHealth() {
        Map<String, Object> detailed = new Map<String, Object>();
        
        detailed.put('systemHealth', getCompleteSystemHealth());
        detailed.put('componentHealth', getDetailedComponentHealth());
        detailed.put('performanceMetrics', getPerformanceMetricsSummary());
        detailed.put('securityMetrics', getSecurityMetricsSummary());
        detailed.put('trends', analyzePerformanceTrends());
        detailed.put('timestamp', DateTime.now());
        detailed.put('apiVersion', '1.0');
        
        return detailed;
    }

    // ==============================================
    // Alerts API
    // ==============================================
    private static Map<String, Object> getActiveAlertsAPI() {
        Map<String, Object> alertData = new Map<String, Object>();
        List<System_Alert__c> activeAlerts = getActiveSystemAlerts();
        
        List<Map<String, Object>> alertList = new List<Map<String, Object>>();
        for (System_Alert__c alert : activeAlerts) {
            Map<String, Object> alertInfo = new Map<String, Object>();
            alertInfo.put('id', alert.Id);
            alertInfo.put('type', alert.Alert_Type__c);
            alertInfo.put('severity', alert.Severity__c);
            alertInfo.put('message', alert.Message__c);
            alertInfo.put('triggeredAt', alert.Triggered_At__c);
            alertInfo.put('component', alert.Component__c);
            alertInfo.put('status', alert.Status__c);
            alertList.add(alertInfo);
        }
        
        alertData.put('alerts', alertList);
        alertData.put('totalAlerts', alertList.size());
        alertData.put('criticalCount', getCriticalAlertCount(activeAlerts));
        alertData.put('timestamp', DateTime.now());
        
        return alertData;
    }

    private static Integer getCriticalAlertCount(List<System_Alert__c> alerts) {
        Integer criticalCount = 0;
        for (System_Alert__c alert : alerts) {
            if (alert.Severity__c == 'CRITICAL') {
                criticalCount++;
            }
        }
        return criticalCount;
    }

    // ==============================================
    // REST API - Acknowledge Alert
    // ==============================================
    @HttpPost
    global static Map<String, Object> acknowledgeAlert() {
        try {
            String requestBody = RestContext.request.requestBody.toString();
            Map<String, Object> requestData = 
                (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            
            String alertId = (String) requestData.get('alertId');
            String userId = (String) requestData.get('userId');
            String notes = (String) requestData.get('notes');
            
            if (String.isBlank(alertId)) {
                return new Map<String, Object>{
                    'status' => 'ERROR',
                    'message' => 'Alert ID is required'
                };
            }
            
            System_Alert__c alert = [
                SELECT Id, Status__c
                FROM System_Alert__c
                WHERE Id = :alertId
                LIMIT 1
            ];
            
            alert.Status__c = 'ACKNOWLEDGED';
            alert.Acknowledged_At__c = DateTime.now();
            alert.Acknowledged_By__c = userId;
            
            if (!String.isBlank(notes)) {
                alert.Acknowledgment_Notes__c = notes;
            }
            
            update alert;
            
            return new Map<String, Object>{
                'status'   => 'SUCCESS',
                'message'  => 'Alert acknowledged successfully',
                'alertId'  => alertId,
                'timestamp'=> DateTime.now()
            };
        } catch (Exception e) {
            return new Map<String, Object>{
                'status'  => 'ERROR',
                'message' => 'Failed to acknowledge alert: ' + e.getMessage()
            };
        }
    }

    // ==============================================
    // Create Default Alert Configurations
    // ==============================================
    private static void createDefaultAlertConfigurations() {
        List<System_Alert_Configuration__c> alertConfigs = new List<System_Alert_Configuration__c>();
        
        // Compliance alerts
        alertConfigs.add(new System_Alert_Configuration__c(
            Alert_Type__c   = 'COMPLIANCE_SCORE_LOW',
            Threshold_Value__c = 85,
            Severity__c     = 'CRITICAL',
            Enabled__c      = true,
            Alert_Message__c= 'Compliance score has fallen below regulatory requirements'
        ));
        
        // Uptime alert
        alertConfigs.add(new System_Alert_Configuration__c(
            Alert_Type__c   = 'UPTIME_LOW',
            Threshold_Value__c = 99,
            Severity__c     = 'HIGH',
            Enabled__c      = true,
            Alert_Message__c= 'System uptime has dropped below SLA requirements'
        ));
        
        // Security incident alert
        alertConfigs.add(new System_Alert_Configuration__c(
            Alert_Type__c   = 'SECURITY_INCIDENTS_HIGH',
            Threshold_Value__c = 3,
            Severity__c     = 'CRITICAL',
            Enabled__c      = true,
            Alert_Message__c= 'Multiple security incidents detected within monitoring period'
        ));
        
        insert alertConfigs;
        System.debug('✓ Alert configurations created: ' + alertConfigs.size() + ' alert types');
    }

    // ==============================================
    // Dashboard Setup
    // ==============================================
    private static void createSystemHealthDashboard() {
        System_Health_Dashboard__c dashboard = new System_Health_Dashboard__c(
            Dashboard_Name__c                = 'Production System Health Monitor',
            Active__c                        = true,
            Refresh_Interval_Minutes__c      = 15,
            Alert_Threshold_Critical__c      = 60,
            Alert_Threshold_Warning__c       = 80,
            Performance_Target_Response_Time__c = 3000,
            Performance_Target_Error_Rate__c = 2,
            Compliance_Target_Score__c       = 90,
            Uptime_Target_Percentage__c      = 99.5,
            Dashboard_Configuration__c       = JSON.serialize(new Map<String, Object>{
                'components' => new List<String>{ 'Database', 'Application', 'Integrations', 'Security', 'Compliance' },
                'metrics'    => new List<String>{ 'responseTime', 'errorRate', 'uptime', 'healthScore', 'compliance' },
                'alerts'     => true,
                'realTimeMonitoring' => true,
                'historicalTrends'   => 30
            }),
            Created_By__c = UserInfo.getUserId(),
            Last_Updated__c = DateTime.now()
        );
        
        insert dashboard;
        System.debug('✓ System Health Dashboard created');
    }

    // ==============================================
    // Monitoring Setup Validation
    // ==============================================
    private static void validateMonitoringSetup() {
        List<String> validationIssues = new List<String>();
        
        // Validate custom objects exist
        try {
            [SELECT COUNT() FROM System_Alert__c LIMIT 1];
        } catch (Exception e) {
            validationIssues.add('System_Alert__c object not accessible');
        }
        
        // Validate permission sets
        List<PermissionSet> permSets = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name IN ('System_Health_Admin', 'System_Health_User')
        ];
        
        if (permSets.size() < 2) {
            validationIssues.add('Required permission sets not found');
        }
        
        // Validate monitoring jobs
        List<CronTrigger> monitoringJobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE '%Health%' AND State = 'WAITING'
        ];
        
        if (monitoringJobs.isEmpty()) {
            validationIssues.add('Health monitoring jobs not scheduled');
        }
        
        if (!validationIssues.isEmpty()) {
            throw new SystemHealthException(
                'Monitoring validation failed: ' + String.join(validationIssues, ', ')
            );
        }
        
        System.debug('✓ Monitoring setup validation completed successfully');
    }

        // ----------------------------------------------------------------------
    // Get System Health Status
    // ----------------------------------------------------------------------
    public static Map<String, Object> getSystemHealthStatus() {
        Map<String, Object> status = new Map<String, Object>();
        
        try {
            SystemHealthMonitor.SystemHealthWrapper health =
                SystemHealthMonitor.getCompleteSystemHealth();
            
            status.put('overall', new Map<String, Object>{
                'healthScore'     => health.overallHealthScore,
                'status'          => health.systemStatus,
                'uptime'          => health.systemUptime,
                'responseTime'    => health.averageResponseTime,
                'errorRate'       => health.errorRate,
                'complianceScore' => health.complianceScore,
                'lastCheck'       => health.lastHealthCheck
            });
            
            status.put('alerts', new Map<String, Object>{
                'total'            => health.totalAlerts,
                'critical'         => health.criticalAlerts,
                'requiresAttention'=> health.requiresAttention,
                'recent'           => health.recentAlerts
            });
            
            status.put('components',      health.componentHealth);
            status.put('recommendations', health.recommendations);
            status.put('trend',           health.healthTrend);
            status.put('performance',     health.performanceMetrics);
            status.put('security',        health.securityMetrics);
            
            status.put('timestamp', DateTime.now());
            status.put('success',   true);
            
        } catch (Exception e) {
            status.put('success',   false);
            status.put('error',     'Failed to retrieve system health status: ' + e.getMessage());
            status.put('timestamp', DateTime.now());
        }
        
        return status;
    }

    // ----------------------------------------------------------------------
    // Execute Emergency Response
    // ----------------------------------------------------------------------
    public static void executeEmergencyResponse(String emergencyType, String description) {
        try {
            System.debug('=== EXECUTING EMERGENCY RESPONSE ===');
            System.debug('Emergency Type: ' + emergencyType);
            System.debug('Description: ' + description);
            
            Emergency_Response__c emergency = new Emergency_Response__c(
                Emergency_Type__c  = emergencyType,
                Description__c     = description,
                Status__c          = 'ACTIVE',
                Initiated_At__c    = DateTime.now(),
                Initiated_By__c    = UserInfo.getUserId(),
                Priority__c        = 'CRITICAL',
                Response_Plan__c   = getEmergencyResponsePlan(emergencyType)
            );
            insert emergency;
            
            createEmergencyAlert(emergencyType, description, emergency.Id);
            executeAutomatedResponse(emergencyType);
            notifyEmergencyTeam(emergency);
            
            System.debug('✓ Emergency response executed: ' + emergency.Id);
            
        } catch (Exception e) {
            System.debug('✗ Emergency response failed: ' + e.getMessage());
            createSystemAlert(
                'EMERGENCY_RESPONSE_FAILED', 
                'CRITICAL', 
                'Emergency response system failure: ' + e.getMessage()
            );
        }
    }

    // ----------------------------------------------------------------------
    // Emergency Response Plan Lookup
    // ----------------------------------------------------------------------
    private static String getEmergencyResponsePlan(String emergencyType) {
        Map<String, String> responsePlans = new Map<String, String>{
            'SYSTEM_OUTAGE'        => 'Activate backup systems, initiate failover procedures, assess impact scope',
            'SECURITY_BREACH'      => 'Isolate affected systems, preserve evidence, notify security team, implement containment',
            'DATA_CORRUPTION'      => 'Stop data processing, activate backup restore procedures, assess data integrity',
            'PERFORMANCE_CRITICAL' => 'Scale resources, optimize critical paths, implement emergency caching',
            'COMPLIANCE_VIOLATION' => 'Document incident, notify compliance team, implement corrective measures'
        };
        
        return responsePlans.containsKey(emergencyType)
            ? responsePlans.get(emergencyType)
            : 'Execute standard emergency response procedures';
    }

    // ----------------------------------------------------------------------
    // Create Emergency Alert
    // ----------------------------------------------------------------------
    private static void createEmergencyAlert(String emergencyType, String description, Id emergencyId) {
        System_Alert__c emergencyAlert = new System_Alert__c(
            Alert_Type__c               = 'EMERGENCY_RESPONSE',
            Severity__c                  = 'CRITICAL',
            Message__c                   = 'EMERGENCY: ' + emergencyType + ' - ' + description,
            Status__c                    = 'ACTIVE',
            Triggered_At__c              = DateTime.now(),
            Component__c                 = 'SYSTEM',
            Impact__c                    = 'HIGH',
            Related_Record_Id__c         = emergencyId,
            Requires_Immediate_Action__c = true,
            Auto_Escalate__c             = true,
            Escalation_Minutes__c        = 5
        );
        insert emergencyAlert;
    }

    // ----------------------------------------------------------------------
    // Execute Automated Response
    // ----------------------------------------------------------------------
    private static void executeAutomatedResponse(String emergencyType) {
        switch on emergencyType {
            when 'SYSTEM_OUTAGE' {
                SystemRecoveryManager.initiateRecovery();
            }
            when 'SECURITY_BREACH' {
                SecurityResponseManager.containBreach();
            }
            when 'PERFORMANCE_CRITICAL' {
                PerformanceOptimizer.emergencyOptimization();
            }
            when 'DATA_CORRUPTION' {
                DataIntegrityManager.protectData();
            }
        }
    }

    // ----------------------------------------------------------------------
    // Notify Emergency Team
    // ----------------------------------------------------------------------
    private static void notifyEmergencyTeam(Emergency_Response__c emergency) {
        List<Emergency_Contact__c> contacts = [
            SELECT Email__c, Phone__c, Contact_Type__c, Name
            FROM Emergency_Contact__c
            WHERE Active__c = true
            AND Emergency_Types__c INCLUDES (:emergency.Emergency_Type__c)
        ];
        
        for (Emergency_Contact__c contact : contacts) {
            sendEmergencyEmail(contact, emergency);
            
            Notification_Log__c notificationLog = new Notification_Log__c(
                Notification_Type__c  = 'EMERGENCY_ALERT',
                Recipient__c          = contact.Email__c,
                Message__c            = 'Emergency response notification sent',
                Sent_At__c            = DateTime.now(),
                Emergency_Response__c = emergency.Id,
                Status__c             = 'SENT'
            );
            insert notificationLog;
        }
    }

    // ----------------------------------------------------------------------
    // Send Emergency Email
    // ----------------------------------------------------------------------
    private static void sendEmergencyEmail(Emergency_Contact__c contact, Emergency_Response__c emergency) {
        try {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{ contact.Email__c });
            email.setSubject('CRITICAL: Emergency Response Activated - ' + emergency.Emergency_Type__c);
            email.setHtmlBody(buildEmergencyEmailBody(emergency));
            email.setSaveAsActivity(false);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ email });
        } catch (Exception e) {
            System.debug('Failed to send emergency email: ' + e.getMessage());
        }
    }

    // ----------------------------------------------------------------------
    // Build Emergency Email Body
    // ----------------------------------------------------------------------
    private static String buildEmergencyEmailBody(Emergency_Response__c emergency) {
        String body = '<html><body>';
        body += '<h2 style="color: #d9534f;">EMERGENCY RESPONSE ACTIVATED</h2>';
        body += '<p><strong>Emergency Type:</strong> ' + emergency.Emergency_Type__c + '</p>';
        body += '<p><strong>Description:</strong> ' + emergency.Description__c + '</p>';
        body += '<p><strong>Time:</strong> ' + emergency.Initiated_At__c.format() + '</p>';
        body += '<p><strong>Priority:</strong> ' + emergency.Priority__c + '</p>';
        body += '<p><strong>Response Plan:</strong> ' + emergency.Response_Plan__c + '</p>';
        body += '<p><strong>Emergency ID:</strong> ' + emergency.Id + '</p>';
        body += '<hr>';
        body += '<p>Please respond immediately according to emergency procedures.</p>';
        body += '<p>Access the emergency dashboard: ';
        body += URL.getSalesforceBaseUrl().toExternalForm() + 
                '/lightning/r/Emergency_Response__c/' + emergency.Id + '/view</p>';
        body += '</body></html>';
        
        return body;
    }


}
