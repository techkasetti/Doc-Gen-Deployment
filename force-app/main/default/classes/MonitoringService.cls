public with sharing class MonitoringService {
    // Lightweight DTO for monitoring configuration
    public class MonitoringConfiguration {
        @AuraEnabled public Boolean enableRealTimeAlerts { get; set; }
        @AuraEnabled public Integer performanceThresholdMs { get; set; }
        @AuraEnabled public Decimal complianceThreshold { get; set; }
        @AuraEnabled public Decimal errorRateThresholdPct { get; set; }
        @AuraEnabled public List<String> alertRecipients { get; set; }
        public MonitoringConfiguration() {
            this.enableRealTimeAlerts = true;
            this.performanceThresholdMs = 5000;
            this.complianceThreshold = 90;
            this.errorRateThresholdPct = 5;
            this.alertRecipients = new List<String>();
        }
    }

    // Health metrics wrapper returned to clients
    public class HealthMetrics {
        @AuraEnabled public String overallStatus { get; set; }
        @AuraEnabled public Decimal systemUptime { get; set; }
        @AuraEnabled public Decimal documentGenerationSLA { get; set; }
        @AuraEnabled public Decimal complianceScore { get; set; }
        @AuraEnabled public Decimal errorRate { get; set; }
        @AuraEnabled public Decimal averageResponseTimeMs { get; set; }
        @AuraEnabled public Map<String, Object> alerts { get; set; }
        @AuraEnabled public List<Map<String, Object>> performanceTrends { get; set; }
        public HealthMetrics() {
            this.alerts = new Map<String, Object>{ 'activeAlerts' => new List<Object>(), 'alertCount' => 0 };
            this.performanceTrends = new List<Map<String, Object>>();
        }
    }

    // --------------------
    // Configuration APIs
    // --------------------
    @AuraEnabled
    public static MonitoringConfiguration getMonitoringConfiguration() {
        MonitoringConfiguration cfg = new MonitoringConfiguration();
        try {
            if (Schema.getGlobalDescribe().containsKey('Monitoring_Configuration__c')) {
                SObject rec = getOrgDefaults('Monitoring_Configuration__c');
                if (rec != null) {
                    Object enable = rec.get('Enable_Real_Time_Alerts__c');
                    cfg.enableRealTimeAlerts = enable != null && ((Boolean)enable);
                    Object threshold = rec.get('Performance_Threshold_Ms__c');
                    if (threshold != null) cfg.performanceThresholdMs = ((Decimal)threshold).intValue();
                    Object compliance = rec.get('Compliance_Threshold__c');
                    if (compliance != null) cfg.complianceThreshold = (Decimal)compliance;
                    Object errorThr = rec.get('Error_Rate_Threshold_Pct__c');
                    if (errorThr != null) cfg.errorRateThresholdPct = (Decimal)errorThr;
                    Object recips = rec.get('Alert_Recipients__c');
                    if (recips != null) cfg.alertRecipients = String.valueOf(recips).split(';');
                }
            }
        } catch (Exception e) {
            System.debug('MonitoringService.getMonitoringConfiguration error: ' + e.getMessage());
        }
        return cfg;
    }

    @AuraEnabled
    public static Map<String, Object> saveMonitoringConfiguration(MonitoringConfiguration cfg) {
        Map<String, Object> result = new Map<String, Object>{ 'success' => false };
        try {
            if (!Schema.getGlobalDescribe().containsKey('Monitoring_Configuration__c')) {
                result.put('error', 'Monitoring_Configuration__c object not present in org');
                return result;
            }
            SObject rec = getOrgDefaults('Monitoring_Configuration__c');
            if (rec == null) rec = Schema.getGlobalDescribe().get('Monitoring_Configuration__c').newSObject();
            rec.put('Enable_Real_Time_Alerts__c', cfg.enableRealTimeAlerts);
            rec.put('Performance_Threshold_Ms__c', cfg.performanceThresholdMs);
            rec.put('Compliance_Threshold__c', cfg.complianceThreshold);
            rec.put('Error_Rate_Threshold_Pct__c', cfg.errorRateThresholdPct);
            rec.put('Alert_Recipients__c', String.join(cfg.alertRecipients, ';'));
            upsert rec;
            Object rid = rec.get('Id');
            if (rid != null) result.put('id', String.valueOf(rid));
            result.put('success', true);
        } catch (Exception e) {
            result.put('error', e.getMessage());
        }
        return result;
    }

    // --------------------
    // Health retrieval and checks
    // --------------------
    @AuraEnabled(cacheable = true)
    public static HealthMetrics getCurrentHealthMetrics() {
        HealthMetrics metrics = new HealthMetrics();
        try {
            // Prefer SystemHealthMonitor if available
            if (Type.forName('SystemHealthMonitor') != null) {
                try {
                    // Assumes SystemHealthMonitor.SystemHealthWrapper is Apex inner class
                    Object wrapper = SystemHealthMonitor.getCompleteSystemHealth();
                    Map<String, Object> wmap = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(wrapper));
                    metrics.systemUptime = (Decimal)wmap.get('systemUptime');
                    metrics.averageResponseTimeMs = (Decimal)wmap.get('averageResponseTime');
                    metrics.documentGenerationSLA = (Decimal)wmap.get('documentGenerationSLA');
                    metrics.complianceScore = (Decimal)wmap.get('complianceScore');
                    metrics.errorRate = (Decimal)wmap.get('errorRate');
                    metrics.overallStatus = (String)wmap.get('systemStatus');

                    // Recent alerts
                    if (wmap.get('recentAlerts') != null) {
                        List<Object> alertList = new List<Object>();
                        List<Object> salist = (List<Object>)wmap.get('recentAlerts');
                        for (Object saObj : salist) {
                            Map<String, Object> sa = (Map<String, Object>)saObj;
                            Map<String, Object> a = new Map<String, Object>();
                            a.put('id', sa.get('alertId'));
                            a.put('type', sa.get('alertType'));
                            a.put('severity', sa.get('severity'));
                            a.put('message', sa.get('message'));
                            a.put('timestamp', sa.get('triggeredAt'));
                            alertList.add(a);
                        }
                        metrics.alerts.put('activeAlerts', alertList);
                        metrics.alerts.put('alertCount', alertList.size());
                    }
                    if (wmap.get('performanceMetrics') != null) {
                        Map<String, Object> pm = (Map<String, Object>)wmap.get('performanceMetrics');
                        Object t = pm.get('performanceTrends');
                        if (t != null) metrics.performanceTrends = (List<Map<String, Object>>) t;
                    }
                    return metrics;
                } catch (Exception e) {
                    System.debug('MonitoringService.getCurrentHealthMetrics: wrapper call failed: ' + e.getMessage());
                }
            }

            // fallback logic
            metrics.averageResponseTimeMs = getRecentAverageResponseTime();
            metrics.errorRate = getRecentErrorRate();
            metrics.documentGenerationSLA = calculateDocumentGenerationSLA();
            metrics.systemUptime = calculateSystemUptimeEstimate();
            metrics.complianceScore = getRecentComplianceScore();
            metrics.overallStatus = determineOverallStatus(metrics);

            // Alerts fallback
            if (Schema.getGlobalDescribe().containsKey('System_Alert__c')) {
                List<System_Alert__c> activeAlerts = [
                    SELECT Id, Alert_Type__c, Severity__c, Message__c, Triggered_At__c
                    FROM System_Alert__c
                    WHERE Status__c = 'ACTIVE'
                    ORDER BY Triggered_At__c DESC
                    LIMIT 50
                ];
                List<Object> alertList = new List<Object>();
                for (System_Alert__c a : activeAlerts) {
                    Map<String, Object> m = new Map<String, Object>();
                    m.put('id', a.Id);
                    m.put('type', a.Alert_Type__c);
                    m.put('severity', a.Severity__c);
                    m.put('message', a.Message__c);
                    m.put('timestamp', a.Triggered_At__c);
                    alertList.add(m);
                }
                metrics.alerts.put('activeAlerts', alertList);
                metrics.alerts.put('alertCount', alertList.size());
            }
        } catch (Exception e) {
            System.debug('MonitoringService.getCurrentHealthMetrics error: ' + e.getMessage());
        }
        return metrics;
    }

    // --------------------
    // Alerting helpers
    // --------------------
    @AuraEnabled
    public static Map<String, Object> createAlert(String alertType, String severity, String message, String component) {
        Map<String, Object> result = new Map<String, Object>{ 'success' => false };
        try {
            if (!Schema.getGlobalDescribe().containsKey('System_Alert__c')) {
                result.put('error', 'System_Alert__c object not present');
                return result;
            }
            System_Alert__c alert = new System_Alert__c();
            alert.put('Alert_Type__c', alertType);
            alert.put('Severity__c', severity);
            alert.put('Message__c', message);
            alert.put('Component__c', component);
            alert.put('Status__c', 'ACTIVE');
            alert.put('Triggered_At__c', DateTime.now()); // dynamic put to avoid type mismatch
            insert alert;

            // Optional downstream notifier
            try {
                if (Type.forName('AlertingSystem') != null) {
                    AlertingSystem.createAlert(alertType, severity, message, component);
                }
            } catch (Exception e) {
                System.debug('MonitoringService.createAlert: alerting system call failed: ' + e.getMessage());
            }

            if (severity == 'CRITICAL' || severity == 'HIGH') {
                sendCriticalAlertNotification(alert);
            }
            result.put('success', true);
            result.put('id', alert.Id);
        } catch (Exception e) {
            result.put('error', e.getMessage());
        }
        return result;
    }

    @AuraEnabled
    public static void acknowledgeAlert(Id alertId) {
        try {
            if (!Schema.getGlobalDescribe().containsKey('System_Alert__c')) {
                throw new AuraHandledException('System_Alert__c not available');
            }
            System_Alert__c a = [SELECT Id, Status__c FROM System_Alert__c WHERE Id = :alertId LIMIT 1];
            a.put('Status__c', 'ACKNOWLEDGED');
            a.put('Acknowledged_At__c', DateTime.now());     // use put() to bypass compile-time type
            a.put('Acknowledged_By__c', UserInfo.getUserId()); // works for Lookup(Text) safely
            update a;

            if (Schema.getGlobalDescribe().containsKey('AuditTrail__c')) {
                AuditTrail__c at = new AuditTrail__c();
                at.put('Action__c', 'ALERT_ACKNOWLEDGED');
                at.put('Status__c', 'INFO');
                at.put('Timestamp__c', DateTime.now());
                at.put('Details__c', 'Alert ' + String.valueOf(alertId) + ' acknowledged by ' + UserInfo.getName());
                insert at;
            }
        } catch (Exception e) {
            throw new AuraHandledException('Failed to acknowledge alert: ' + e.getMessage());
        }
    }

    // --------------------
    // Scheduling helpers
    // --------------------
    @AuraEnabled
    public static Map<String, Object> scheduleMonitoringJob(String jobName, String cronExpression) {
        Map<String, Object> out = new Map<String, Object>{ 'success' => false };
        try {
            System.schedule(jobName, cronExpression, new MonitoringScheduler());
            out.put('success', true);
            out.put('jobName', jobName);
        } catch (Exception e) {
            out.put('error', e.getMessage());
        }
        return out;
    }

    // Make inner class PUBLIC (not global) so the outer class can remain public
    public class MonitoringScheduler implements Schedulable {
        public void execute(SchedulableContext sc) {
            try {
                performHealthCheck();
            } catch (Exception e) {
                System.debug('MonitoringScheduler.execute error: ' + e.getMessage());
            }
        }
    }

    @AuraEnabled
    public static Map<String, Object> performHealthCheck() {
        Map<String, Object> result = new Map<String, Object>{ 'success' => false };
        try {
            HealthMetrics metrics = getCurrentHealthMetrics();
            MonitoringConfiguration cfg = getMonitoringConfiguration();
            if (metrics.averageResponseTimeMs != null && metrics.averageResponseTimeMs > cfg.performanceThresholdMs) {
                createAlert('PERFORMANCE_DEGRADATION', 'HIGH', 'Average response time ' + metrics.averageResponseTimeMs.setScale(0) + ' ms', 'PERFORMANCE');
            }
            if (metrics.errorRate != null && metrics.errorRate > cfg.errorRateThresholdPct) {
                createAlert('HIGH_ERROR_RATE', 'CRITICAL', 'Error rate ' + metrics.errorRate.setScale(2) + '%', 'SYSTEM');
            }
            if (metrics.complianceScore != null && metrics.complianceScore < cfg.complianceThreshold) {
                createAlert('COMPLIANCE_DEGRADATION', 'HIGH', 'Compliance score ' + metrics.complianceScore.setScale(1) + ' below threshold', 'COMPLIANCE');
            }
            createHealthSnapshot(metrics);
            result.put('success', true);
            result.put('metrics', metrics);
        } catch (Exception e) {
            result.put('error', e.getMessage());
        }
        return result;
    }

    // --------------------
    // Snapshot storage
    // --------------------
    public static void createHealthSnapshot(HealthMetrics metrics) {
        try {
            if (!Schema.getGlobalDescribe().containsKey('Performance_Snapshot__c')) return;
            Performance_Snapshot__c snap = new Performance_Snapshot__c();
            snap.put('Snapshot_Time__c', DateTime.now());
            snap.put('Average_Response_Time__c', metrics.averageResponseTimeMs);
            snap.put('Error_Rate__c', metrics.errorRate);
            snap.put('Throughput__c', 0);
            snap.put('System_Uptime__c', metrics.systemUptime);
            insert snap;
        } catch (Exception e) {
            System.debug('MonitoringService.createHealthSnapshot failed: ' + e.getMessage());
        }
    }

    // Small utility: returns org default record for given API name
    private static SObject getOrgDefaults(String sobjectApiName) {
        try {
            SObjectType typ = Schema.getGlobalDescribe().get(sobjectApiName);
            Schema.DescribeSObjectResult d = typ.getDescribe();
            // standard pattern to get fields:
            Map<String, Schema.SObjectField> fieldMap = d.fields.getMap();
            List<String> fieldNames = new List<String>(fieldMap.keySet());
            String soql = 'SELECT ' + String.join(fieldNames, ',') + ' FROM ' + sobjectApiName + ' LIMIT 1';
            List<SObject> found = Database.query(soql);
            if (!found.isEmpty()) return found[0];
        } catch (Exception e) {
            // ignore
        }
        return null;
    }

    // --------------------
    // Utility helpers
    // --------------------
    private static Decimal getRecentAverageResponseTime() {
        try {
            if (!Schema.getGlobalDescribe().containsKey('Performance_Log__c')) return 0;
            AggregateResult[] rr = [
                SELECT AVG(Response_Time_Ms__c) avgTime
                FROM Performance_Log__c
                WHERE CreatedDate >= :DateTime.now().addHours(-1)
            ];
            if (!rr.isEmpty() && rr[0].get('avgTime') != null) return (Decimal) rr[0].get('avgTime');
        } catch (Exception e) {
            System.debug('getRecentAverageResponseTime error: ' + e.getMessage());
        }
        return 0;
    }

    private static Decimal getRecentErrorRate() {
        try {
            if (!Schema.getGlobalDescribe().containsKey('System_Operation_Log__c')) return 0;
            Integer total = [SELECT COUNT() FROM System_Operation_Log__c WHERE CreatedDate >= :DateTime.now().addHours(-1)];
            Integer errors = [SELECT COUNT() FROM System_Operation_Log__c WHERE CreatedDate >= :DateTime.now().addHours(-1) AND Status__c IN ('ERROR', 'FAILED')];
            if (total > 0) return (Decimal.valueOf(errors) * 100) / total;
        } catch (Exception e) {
            System.debug('getRecentErrorRate error: ' + e.getMessage());
        }
        return 0;
    }

    private static Decimal calculateDocumentGenerationSLA() {
        try {
            if (!Schema.getGlobalDescribe().containsKey('Document_Generation_Log__c')) return 100;
            AggregateResult[] ar = [
                SELECT AVG(Processing_Time__c) avgTime
                FROM Document_Generation_Log__c
                WHERE CreatedDate >= :DateTime.now().addDays(-1)
            ];
            if (!ar.isEmpty() && ar[0].get('avgTime') != null) {
                Decimal avg = (Decimal) ar[0].get('avgTime');
                return Math.max(0, 100 - (avg / 10));
            }
        } catch (Exception e) {
            System.debug('calculateDocumentGenerationSLA error: ' + e.getMessage());
        }
        return 100;
    }

    private static Decimal calculateSystemUptimeEstimate() {
        return 99.9;
    }

    private static Decimal getRecentComplianceScore() {
        try {
            if (Schema.getGlobalDescribe().containsKey('Compliance_Score__c')) {
                List<SObject> rows = Database.query(
                    'SELECT Score__c FROM Compliance_Score__c ORDER BY CreatedDate DESC LIMIT 1'
                );
                if (!rows.isEmpty()) return (Decimal) rows[0].get('Score__c');
            }
        } catch (Exception e) {
            System.debug('getRecentComplianceScore error: ' + e.getMessage());
        }
        return 100;
    }

    private static String determineOverallStatus(HealthMetrics m) {
        if (m.documentGenerationSLA < 60 || m.systemUptime < 95 || m.complianceScore < 80 || (m.errorRate != null && m.errorRate > 10)) {
            return 'CRITICAL';
        } else if (m.documentGenerationSLA < 80 || m.systemUptime < 99 || m.complianceScore < 90 || (m.errorRate != null && m.errorRate > 5)) {
            return 'DEGRADED';
        }
        return 'HEALTHY';
    }

    private static void sendCriticalAlertNotification(System_Alert__c alertRecord) {
        try {
            List<User> admins = [SELECT Email FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true];
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            for (User u : admins) {
                if (u.Email == null) continue;
                Messaging.SingleEmailMessage m = new Messaging.SingleEmailMessage();
                m.setToAddresses(new String[]{ u.Email });
                m.setSubject('CRITICAL ALERT: ' + alertRecord.Alert_Type__c);
                String body = 'A critical system alert occurred:\n\n'
                    + 'Type: ' + alertRecord.Alert_Type__c + '\n'
                    + 'Message: ' + alertRecord.Message__c + '\n'
                    + 'Component: ' + alertRecord.Component__c + '\n'
                    + 'Time: ' + String.valueOf(alertRecord.get('Triggered_At__c')) + '\n\n'
                    + 'Please investigate immediately.';
                m.setPlainTextBody(body);
                emails.add(m);
            }
            if (!emails.isEmpty()) Messaging.sendEmail(emails);
        } catch (Exception e) {
            System.debug('sendCriticalAlertNotification failed: ' + e.getMessage());
        }
    }
}