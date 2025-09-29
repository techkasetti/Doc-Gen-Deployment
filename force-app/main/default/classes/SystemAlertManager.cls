public class SystemAlertManager {
    
    public enum AlertPriority { LOW, MEDIUM, HIGH, CRITICAL }
    public enum AlertType { 
        PERFORMANCE_DEGRADATION,
        COMPLIANCE_VIOLATION,
        SYSTEM_ERROR,
        SECURITY_BREACH,
        CAPACITY_WARNING,
        INTEGRATION_FAILURE
    }
    
    @AuraEnabled
    public static List<SystemAlert__c> getActiveAlerts() {
        return [
            SELECT Id, AlertType__c, Message__c, Priority__c, AlertDate__c, Status__c
            FROM SystemAlert__c 
            WHERE Status__c = 'ACTIVE' 
            ORDER BY Priority__c DESC, AlertDate__c DESC
            LIMIT 50
        ];
    }
    
    
@AuraEnabled
public static void acknowledgeAlert(Id alertId) {
    try {
        SystemAlert__c alert = [SELECT Id, Status__c FROM SystemAlert__c WHERE Id = :alertId];
        alert.Status__c = 'ACKNOWLEDGED';
        alert.AcknowledgedDate__c = System.now();
        alert.AcknowledgedBy__c = UserInfo.getUserId();
        update alert;
        
        // Create audit trail for alert acknowledgment
        AuditTrail__c audit = new AuditTrail__c(
            Action__c = 'Alert Acknowledged',
            User__c = UserInfo.getUserId(),
            Timestamp__c = System.now(),
            RelatedRecordId__c = alertId,
            Details__c = 'Alert acknowledged by ' + UserInfo.getName()
        );
        insert audit;
    } catch (Exception e) {
        throw new AuraHandledException('Failed to acknowledge alert: ' + e.getMessage());
    }
}

@AuraEnabled
public static void resolveAlert(Id alertId, String resolution) {
    try {
        SystemAlert__c alert = [SELECT Id, Status__c FROM SystemAlert__c WHERE Id = :alertId];
        alert.Status__c = 'RESOLVED';
        alert.ResolvedDate__c = System.now();
        alert.ResolvedBy__c = UserInfo.getUserId();
        alert.Resolution__c = resolution;
        update alert;
        
        // Create audit trail for alert resolution
        AuditTrail__c audit = new AuditTrail__c(
            Action__c = 'Alert Resolved',
            User__c = UserInfo.getUserId(),
            Timestamp__c = System.now(),
            RelatedRecordId__c = alertId,
            Details__c = 'Alert resolved by ' + UserInfo.getName() + ': ' + resolution
        );
        insert audit;
    } catch (Exception e) {
        throw new AuraHandledException('Failed to resolve alert: ' + e.getMessage());
    }
}

public static void createAlert(AlertType alertType, String message, AlertPriority priority) {
    createAlert(alertType, message, priority, null);
}

public static void createAlert(AlertType alertType, String message, AlertPriority priority, Id relatedRecordId) {
    try {
        SystemAlert__c newAlert = new SystemAlert__c(
            AlertType__c = alertType.name(),
            Message__c = message,
            Priority__c = priority.name(),
            Status__c = 'ACTIVE',
            AlertDate__c = System.now(),
            RelatedRecordId__c = relatedRecordId
        );
        insert newAlert;
        
        // Send immediate notification for critical alerts
        if (priority == AlertPriority.CRITICAL) {
            sendCriticalAlertNotification(newAlert);
        }
        
        System.debug('✅ System alert created: ' + alertType + ' - ' + message);
    } catch (Exception e) {
        System.debug('❌ Failed to create system alert: ' + e.getMessage());
    }
}

private static void sendCriticalAlertNotification(SystemAlert__c alert) {
    try {
        // Get system administrators
        List<User> admins = [
            SELECT Email, Name FROM User 
            WHERE Profile.Name = 'System Administrator' 
            AND IsActive = true
        ];
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
        for (User admin : admins) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{admin.Email});
            email.setSubject('CRITICAL ALERT: ' + alert.AlertType__c);
            email.setHtmlBody(
                '<html><body>' +
                '<h2 style="color: red;">CRITICAL SYSTEM ALERT</h2>' +
                '<p><strong>Alert Type:</strong> ' + alert.AlertType__c + '</p>' +
                '<p><strong>Message:</strong> ' + alert.Message__c + '</p>' +
                '<p><strong>Time:</strong> ' + alert.AlertDate__c + '</p>' +
                '<p>Please log into Salesforce to acknowledge and resolve this alert.</p>' +
                '</body></html>'
            );
            emails.add(email);
        }
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    } catch (Exception e) {
        System.debug('Failed to send critical alert notification: ' + e.getMessage());
    }
}

@AuraEnabled
public static Map<String, Integer> getAlertSummary() {
    Map<String, Integer> summary = new Map<String, Integer>();
    
    List<AggregateResult> results = [
        SELECT Priority__c, COUNT(Id) totalcount
        FROM SystemAlert__c
        WHERE Status__c = 'ACTIVE'
        GROUP BY Priority__c
    ];
    
    // Initialize all priorities to 0
    summary.put('CRITICAL', 0);
    summary.put('HIGH', 0);
    summary.put('MEDIUM', 0);
    summary.put('LOW', 0);
    
    for (AggregateResult result : results) {
        summary.put((String)result.get('Priority__c'), (Integer)result.get('count'));
    }
    
    return summary;
}
}
