public class SystemAlertSummary {
    @AuraEnabled public String alertId { get; set; }
    @AuraEnabled public String alertType { get; set; }
    @AuraEnabled public String severity { get; set; }
    @AuraEnabled public String message { get; set; }
    @AuraEnabled public DateTime triggeredAt { get; set; }
    @AuraEnabled public String status { get; set; }
    @AuraEnabled public Boolean acknowledged { get; set; }
    @AuraEnabled public String component { get; set; }
    @AuraEnabled public Integer durationMinutes { get; set; }
    @AuraEnabled public String impact { get; set; }
    
    public SystemAlertSummary(System_Alert__c alert) {
        this.alertId = alert.Id;
        this.alertType = alert.Alert_Type__c;
        this.severity = alert.Severity__c;
        this.message = alert.Message__c;
        this.triggeredAt = alert.Triggered_At__c;
        this.status = alert.Status__c;
        this.acknowledged = alert.Acknowledged_At__c != null;
        this.component = alert.Component__c;
        this.impact = alert.Impact__c;
        
        if (alert.Triggered_At__c != null) {
            this.durationMinutes = Integer.valueOf((DateTime.now().getTime() - alert.Triggered_At__c.getTime()) / (1000 * 60));
        }
    }
}