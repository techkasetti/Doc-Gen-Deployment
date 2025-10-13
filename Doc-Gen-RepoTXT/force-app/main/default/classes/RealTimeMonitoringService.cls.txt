public class RealTimeMonitoringService {

    public class MonitoringConfiguration {
        @AuraEnabled public Boolean enableRealTimeAlerts { get; set; }
        @AuraEnabled public Integer performanceThreshold { get; set; }
        @AuraEnabled public Integer complianceThreshold { get; set; }
        @AuraEnabled public Integer errorRateThreshold { get; set; }
        @AuraEnabled public List<String> alertRecipients { get; set; }
        @AuraEnabled public String escalationPath { get; set; }
    }

    public class SystemAlert {
        @AuraEnabled public String alertId { get; set; }
        @AuraEnabled public String alertType { get; set; }
        @AuraEnabled public String severity { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public DateTime timestamp { get; set; }
        @AuraEnabled public String source { get; set; }
        @AuraEnabled public Map<String, Object> metadata { get; set; }
        @AuraEnabled public Boolean acknowledged { get; set; }
    }

    public class PerformanceTrend {
        @AuraEnabled public DateTime timestamp { get; set; }
        @AuraEnabled public Decimal documentGenerationTime { get; set; }
        @AuraEnabled public Decimal systemResponseTime { get; set; }
        @AuraEnabled public Integer concurrentUsers { get; set; }
        @AuraEnabled public Decimal cacheHitRatio { get; set; }
        @AuraEnabled public Decimal errorRate { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static List<SystemAlert> getActiveAlerts() {
        try {
            List<SystemAlert__c> alertRecords = [
                SELECT Id, Alert_Type__c, Severity__c, Message__c,
                       CreatedDate, Source_System__c, Metadata__c, Acknowledged__c
                FROM SystemAlert__c
                WHERE Acknowledged__c = false
                  AND Status__c = 'ACTIVE'
                ORDER BY CreatedDate DESC
                LIMIT 50
            ];

            List<SystemAlert> alerts = new List<SystemAlert>();

            for (SystemAlert__c alertRecord : alertRecords) {
                SystemAlert alert = new SystemAlert();
                alert.alertId = alertRecord.Id;
                alert.alertType = alertRecord.Alert_Type__c;
                alert.severity = alertRecord.Severity__c;
                alert.message = alertRecord.Message__c;
                alert.timestamp = alertRecord.CreatedDate;
                alert.source = alertRecord.Source_System__c;
                alert.acknowledged = alertRecord.Acknowledged__c;

                if (String.isNotBlank(alertRecord.Metadata__c)) {
                    try {
                        alert.metadata = (Map<String, Object>)JSON.deserializeUntyped(alertRecord.Metadata__c);
                    } catch (Exception e) {
                        alert.metadata = new Map<String, Object>();
                    }
                }

                alerts.add(alert);
            }

            return alerts;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve active alerts: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void acknowledgeAlert(String alertId) {
        try {
            SystemAlert__c alert = [
                SELECT Id, Acknowledged__c, Acknowledged_By__c, Acknowledged_Date__c
                FROM SystemAlert__c
                WHERE Id = :alertId
                LIMIT 1
            ];

            alert.Acknowledged__c = true;
            alert.Acknowledged_By__c = UserInfo.getUserId();
            alert.Acknowledged_Date__c = DateTime.now();

            update alert;

            createAuditLog('ALERT_ACKNOWLEDGED', 'Alert ' + alertId + ' acknowledged by ' + UserInfo.getName());
        } catch (Exception e) {
            throw new AuraHandledException('Failed to acknowledge alert: ' + e.getMessage());
        }
    }

    public static void generatePerformanceAlert(String alertType, String message, Map<String, Object> metadata) {
        try {
            MonitoringConfiguration config = getMonitoringConfiguration();

            if (!config.enableRealTimeAlerts) {
                return;
            }

            String severity = determineSeverity(alertType, metadata);

            SystemAlert__c alert = new SystemAlert__c();
            alert.Alert_Type__c = alertType;
            alert.Severity__c = severity;
            alert.Message__c = message;
            alert.Source_System__c = 'DOCUMENT_GENERATION';
            alert.Status__c = 'ACTIVE';
            alert.Acknowledged__c = false;

            if (metadata != null && !metadata.isEmpty()) {
                alert.Metadata__c = JSON.serialize(metadata);
            }

            insert alert;

            if (severity == 'CRITICAL' || severity == 'HIGH') {
                sendImmediateNotification(alert, config);
            }
        } catch (Exception e) {
            System.debug('Failed to generate performance alert: ' + e.getMessage());
        }
    }

    // private static String determineSeverity(String alertType, Map<String, Object> metadata) {
    //     MonitoringConfiguration config = getMonitoringConfiguration();

    //     switch (alertType) {
    //         case 'PERFORMANCE_DEGRADATION':
    //             Decimal responseTime = (Decimal)metadata.get('responseTime');
    //             if (responseTime > config.performanceThreshold * 2) return 'CRITICAL';
    //             if (responseTime > config.performanceThreshold) return 'HIGH';
    //             return 'MEDIUM';

    //         case 'COMPLIANCE_VIOLATION':
    //             Decimal complianceScore = (Decimal)metadata.get('complianceScore');
    //             if (complianceScore < config.complianceThreshold - 20) return 'CRITICAL';
    //             if (complianceScore < config.complianceThreshold) return 'HIGH';
    //             return 'MEDIUM';

    //         case 'ERROR_RATE_SPIKE':
    //             Decimal errorRate = (Decimal)metadata.get('errorRate');
    //             if (errorRate > config.errorRateThreshold * 3) return 'CRITICAL';
    //             if (errorRate > config.errorRateThreshold) return 'HIGH';
    //             return 'MEDIUM';

    //         default:
    //             return 'MEDIUM';
    //     }
    // }
    private static String determineSeverity(String alertType, Map<String, Object> metadata) {
        MonitoringConfiguration config = getMonitoringConfiguration();

        if (alertType == 'PERFORMANCE_DEGRADATION') {
            Decimal responseTime = (Decimal)metadata.get('responseTime');
            if (responseTime != null) {
                if (responseTime > config.performanceThreshold * 2) return 'CRITICAL';
                if (responseTime > config.performanceThreshold) return 'HIGH';
            }
            return 'MEDIUM';
        }

        if (alertType == 'COMPLIANCE_VIOLATION') {
            Decimal complianceScore = (Decimal)metadata.get('complianceScore');
            if (complianceScore != null) {
                if (complianceScore < config.complianceThreshold - 20) return 'CRITICAL';
                if (complianceScore < config.complianceThreshold) return 'HIGH';
            }
            return 'MEDIUM';
        }

        if (alertType == 'ERROR_RATE_SPIKE') {
            Decimal errorRate = (Decimal)metadata.get('errorRate');
            if (errorRate != null) {
                if (errorRate > config.errorRateThreshold * 3) return 'CRITICAL';
                if (errorRate > config.errorRateThreshold) return 'HIGH';
            }
            return 'MEDIUM';
        }

        return 'MEDIUM';
    }


    private static void sendImmediateNotification(SystemAlert__c alert, MonitoringConfiguration config) {
        try {
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

            for (String recipient : config.alertRecipients) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[]{recipient});
                email.setSubject('Critical System Alert: ' + alert.Alert_Type__c);
                email.setPlainTextBody(buildAlertEmailBody(alert));
                emails.add(email);
            }

            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
            }
        } catch (Exception e) {
            System.debug('Failed to send immediate notification: ' + e.getMessage());
        }
    }

    private static String buildAlertEmailBody(SystemAlert__c alert) {
        StringBuilder body = new StringBuilder();
        body.append('A critical system alert has been generated:\n\n');
        body.append('Alert Type: ').append(alert.Alert_Type__c).append('\n');
        body.append('Severity: ').append(alert.Severity__c).append('\n');
        body.append('Message: ').append(alert.Message__c).append('\n');
        body.append('Timestamp: ').append(alert.CreatedDate).append('\n');
        body.append('Source: ').append(alert.Source_System__c).append('\n\n');
        body.append('Please log into the system to review and acknowledge this alert.\n');
        body.append('Alert ID: ').append(alert.Id).append('\n');
        return body.toString();
    }

    @AuraEnabled(cacheable=true)
    public static List<PerformanceTrend> getPerformanceTrends(Integer hours) {
        try {
            DateTime startTime = DateTime.now().addHours(-hours);
            List<PerformanceTrend> trends = new List<PerformanceTrend>();

            List<AggregateResult> trendData = [
                SELECT
                    HOUR_IN_DAY(CreatedDate) hourValue,
                    DAY_ONLY(CreatedDate) dayValue,
                    AVG(Generation_Time_Ms__c) avgGenerationTime,
                    AVG(Response_Time_Ms__c) avgResponseTime,
                    MAX(Concurrent_Users__c) maxUsers,
                    AVG(Cache_Hit_Ratio__c) avgCacheHit,
                    AVG(Error_Rate__c) avgErrorRate
                FROM Performance_Metrics__c
                WHERE CreatedDate >= :startTime
                GROUP BY HOUR_IN_DAY(CreatedDate), DAY_ONLY(CreatedDate)
                ORDER BY DAY_ONLY(CreatedDate) DESC, HOUR_IN_DAY(CreatedDate) DESC
                LIMIT 100
            ];

            for (AggregateResult result : trendData) {
                PerformanceTrend trend = new PerformanceTrend();
                Date dayValue = (Date)result.get('dayValue');
                Integer hourValue = (Integer)result.get('hourValue');

                trend.timestamp = DateTime.newInstance(dayValue.year(), dayValue.month(), dayValue.day(), hourValue, 0, 0);
                trend.documentGenerationTime = ((Decimal)result.get('avgGenerationTime') / 1000).setScale(2);
                trend.systemResponseTime = ((Decimal)result.get('avgResponseTime') / 1000).setScale(2);
                trend.concurrentUsers = (Integer)result.get('maxUsers');
                trend.cacheHitRatio = ((Decimal)result.get('avgCacheHit')).setScale(1);
                trend.errorRate = ((Decimal)result.get('avgErrorRate')).setScale(2);

                trends.add(trend);
            }

            return trends;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to retrieve performance trends: ' + e.getMessage());
        }
    }

    private static MonitoringConfiguration getMonitoringConfiguration() {
        MonitoringConfiguration config = new MonitoringConfiguration();

        try {
            Monitoring_Configuration__c settingsRecord = Monitoring_Configuration__c.getOrgDefaults();

            if (settingsRecord != null) {
                config.enableRealTimeAlerts = settingsRecord.Enable_Real_Time_Alerts__c;
                config.performanceThreshold = Integer.valueOf(settingsRecord.Performance_Threshold_Ms__c);
                config.complianceThreshold = Integer.valueOf(settingsRecord.Compliance_Threshold__c);
                config.errorRateThreshold = Integer.valueOf(settingsRecord.Error_Rate_Threshold__c);

                if (String.isNotBlank(settingsRecord.Alert_Recipients__c)) {
                    config.alertRecipients = settingsRecord.Alert_Recipients__c.split(',');
                }

                config.escalationPath = settingsRecord.Escalation_Path__c;
            } else {
                config.enableRealTimeAlerts = true;
                config.performanceThreshold = 5000;
                config.complianceThreshold = 95;
                config.errorRateThreshold = 5;
                config.alertRecipients = new List<String>{'admin@company.com'};
                config.escalationPath = 'STANDARD';
            }
        } catch (Exception e) {
            System.debug('Failed to load monitoring configuration: ' + e.getMessage());
            config.enableRealTimeAlerts = true;
            config.performanceThreshold = 5000;
            config.complianceThreshold = 95;
            config.errorRateThreshold = 5;
            config.alertRecipients = new List<String>();
        }

        return config;
    }

    @future
    public static void processMetricsAndGenerateAlerts() {
        try {
            SystemHealthMonitor.HealthMetrics currentMetrics = SystemHealthMonitor.getCurrentHealthMetrics();

            if (currentMetrics.documentGenerationSLA < 80) {
                Map<String, Object> metadata = new Map<String, Object>{
                    'slaCompliance' => currentMetrics.documentGenerationSLA,
                    'threshold' => 95,
                    'responseTime' => currentMetrics.avgResponseTime
                };
                generatePerformanceAlert(
                    'SLA_VIOLATION',
                    'Document generation SLA has dropped to ' + currentMetrics.documentGenerationSLA.setScale(1) + '%',
                    metadata
                );
            }

            if (currentMetrics.systemUptime < 99.0) {
                Map<String, Object> metadata = new Map<String, Object>{
                    'uptime' => currentMetrics.systemUptime,
                    'threshold' => 99.5
                };
                generatePerformanceAlert(
                    'UPTIME_DEGRADATION',
                    'System uptime has decreased to ' + currentMetrics.systemUptime.setScale(2) + '%',
                    metadata
                );
            }

            if (currentMetrics.complianceScore < 90) {
                Map<String, Object> metadata = new Map<String, Object>{
                    'complianceScore' => currentMetrics.complianceScore,
                    'threshold' => 95
                };
                generatePerformanceAlert(
                    'COMPLIANCE_VIOLATION',
                    'Compliance score has dropped to ' + currentMetrics.complianceScore.setScale(1) + '%',
                    metadata
                );
            }

            if (currentMetrics.errorRate > 5.0) {
                Map<String, Object> metadata = new Map<String, Object>{
                    'errorRate' => currentMetrics.errorRate,
                    'threshold' => 1.0
                };
                generatePerformanceAlert(
                    'ERROR_RATE_SPIKE',
                    'Error rate has increased to ' + currentMetrics.errorRate.setScale(2) + '%',
                    metadata
                );
            }

        } catch (Exception e) {
            System.debug('Failed to process metrics and generate alerts: ' + e.getMessage());
        }
    }

    private static void createAuditLog(String action, String details) {
        try {
            Audit_Trail__c auditRecord = new Audit_Trail__c();
            auditRecord.Action__c = action;
            auditRecord.Details__c = details;
            auditRecord.User_Id__c = UserInfo.getUserId();
            auditRecord.Timestamp__c = DateTime.now();
            auditRecord.Source_System__c = 'MONITORING_SERVICE';
            insert auditRecord;
        } catch (Exception e) {
            System.debug('Failed to create audit log: ' + e.getMessage());
        }
    }
}
