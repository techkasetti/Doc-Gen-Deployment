/**
 * @description Essential Alerting System - Core alert management only
 */
public with sharing class AlertingSystem {
    
    // =====================
    // Create Alert
    // =====================
    @AuraEnabled
    public static Map<String, Object> createAlert(
        String alertType,
        String severity,
        String message,
        String component
    ) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            System_Alert__c alert = new System_Alert__c(
                Alert_Type__c   = alertType,
                Severity__c     = severity,
                Message__c      = message,
                Component__c    = component,
                Status__c       = 'ACTIVE',
                Created_By__c   = UserInfo.getUserId()
            );
            insert alert;
            
            // Send notification for critical alerts
            if (severity == 'CRITICAL') {
                sendCriticalAlertNotification(alert);
            }
            
            result.put('success', true);
            result.put('alertId', alert.Id);
        } catch (Exception e) {
            result.put('success', false);
            result.put('error', e.getMessage());
        }
        
        return result;
    }
    
    // =====================
    // Get Active Alerts
    // =====================
    @AuraEnabled
    public static List<Map<String, Object>> getActiveAlerts() {
        List<Map<String, Object>> alerts = new List<Map<String, Object>>();
        
        try {
            List<System_Alert__c> activeAlerts = [
                SELECT Id, Alert_Type__c, Severity__c, Message__c, Component__c, CreatedDate
                FROM System_Alert__c 
                WHERE Status__c = 'ACTIVE'
                ORDER BY Severity__c DESC, CreatedDate DESC
                LIMIT 50
            ];
            
            for (System_Alert__c alert : activeAlerts) {
                Map<String, Object> alertData = new Map<String, Object>();
                alertData.put('id', alert.Id);
                alertData.put('type', alert.Alert_Type__c);
                alertData.put('severity', alert.Severity__c);
                alertData.put('message', alert.Message__c);
                alertData.put('component', alert.Component__c);
                alertData.put('createdDate', alert.CreatedDate);
                alertData.put('urgencyClass', getSeverityClass(alert.Severity__c));
                alerts.add(alertData);
            }
        } catch (Exception e) {
            System.debug('Error retrieving active alerts: ' + e.getMessage());
        }
        
        return alerts;
    }
    
    // =====================
    // Resolve Alert
    // =====================
    @AuraEnabled
    public static Map<String, Object> resolveAlert(String alertId, String resolution) {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            System_Alert__c alert = [
                SELECT Id, Status__c 
                FROM System_Alert__c 
                WHERE Id = :alertId 
                LIMIT 1
            ];
            
            alert.Status__c          = 'RESOLVED';
            alert.Resolved_By__c     = UserInfo.getUserId();
            alert.Resolved_Date__c   = DateTime.now();
            alert.Resolution_Notes__c = resolution;
            
            update alert;
            
            result.put('success', true);
            result.put('message', 'Alert resolved successfully');
        } catch (Exception e) {
            result.put('success', false);
            result.put('error', e.getMessage());
        }
        
        return result;
    }
    
    // =====================
    // Threshold Checks
    // =====================
    public static void checkSystemThresholds() {
        try {
            // Response time threshold
            Decimal avgResponseTime = PerformanceMonitor.getCurrentResponseTime();
            if (avgResponseTime > 5000) {
                createAlert(
                    'PERFORMANCE_DEGRADATION',
                    'HIGH',
                    'Average response time is ' + avgResponseTime.setScale(0) + 'ms',
                    'PERFORMANCE'
                );
            }
            
            // Error rate threshold
            Decimal errorRate = PerformanceMonitor.getCurrentErrorRate();
            if (errorRate > 5) {
                createAlert(
                    'HIGH_ERROR_RATE',
                    'CRITICAL',
                    'Error rate is ' + errorRate.setScale(2) + '%',
                    'SYSTEM'
                );
            }
            
            // Resource usage
            checkSystemResources();
            
        } catch (Exception e) {
            System.debug('Threshold check error: ' + e.getMessage());
        }
    }
    
    // =====================
    // Critical Notifications
    // =====================
    private static void sendCriticalAlertNotification(System_Alert__c alert) {
        try {
            // Collect admin emails
            List<String> toAddresses = new List<String>();
            List<User> admins = [
                SELECT Email 
                FROM User 
                WHERE Profile.Name = 'System Administrator' 
                AND IsActive = true
            ];
            
            for (User admin : admins) {
                toAddresses.add(admin.Email);
            }
            
            // Send email
            if (!toAddresses.isEmpty()) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(toAddresses);
                email.setSubject('CRITICAL ALERT: ' + alert.Alert_Type__c);
                email.setPlainTextBody(
                    'A critical system alert has been triggered:\n\n' +
                    'Component: ' + alert.Component__c + '\n' +
                    'Message: ' + alert.Message__c + '\n' +
                    'Time: ' + alert.CreatedDate + '\n\n' +
                    'Please investigate immediately.'
                );
                
                Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
            }
        } catch (Exception e) {
            System.debug('Failed to send critical alert notification: ' + e.getMessage());
        }
    }
    
    // =====================
    // Severity Mapping
    // =====================
    private static String getSeverityClass(String severity) {
        switch on severity {
            when 'CRITICAL' {
                return 'slds-text-color_error';
            }
            when 'HIGH' {
                return 'slds-text-color_warning';
            }
            when 'MEDIUM' {
                return 'slds-text-color_default';
            }
            when else {
                return 'slds-text-color_weak';
            }
        }
    }
    
    // =====================
    // System Resource Checks
    // =====================
    private static void checkSystemResources() {
        // Active jobs
        Integer activeJobs = [
            SELECT COUNT() 
            FROM AsyncApexJob 
            WHERE Status IN ('Processing', 'Queued')
        ];
        
        if (activeJobs > 20) {
            createAlert(
                'HIGH_SYSTEM_LOAD',
                'MEDIUM',
                'High number of active jobs: ' + activeJobs,
                'SYSTEM'
            );
        }
        
        // Governor limits
        Integer soqlUsage = Limits.getQueries();
        Integer soqlLimit = Limits.getLimitQueries();
        
        if (soqlUsage > (soqlLimit * 0.8)) {
            createAlert(
                'GOVERNOR_LIMIT_WARNING',
                'HIGH',
                'SOQL queries at ' + ((soqlUsage * 100) / soqlLimit) + '% of limit',
                'SYSTEM'
            );
        }
    }
}
