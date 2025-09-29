 public class SystemHealthWrapper {
    @AuraEnabled public Decimal overallHealthScore { get; set; }
    @AuraEnabled public String systemStatus { get; set; }
    @AuraEnabled public Decimal systemUptime { get; set; }
    @AuraEnabled public Decimal averageResponseTime { get; set; }
    @AuraEnabled public Decimal errorRate { get; set; }
    @AuraEnabled public Integer activeUsers { get; set; }
    @AuraEnabled public Decimal complianceScore { get; set; }
    @AuraEnabled public Integer criticalAlerts { get; set; }
    @AuraEnabled public Integer totalAlerts { get; set; }
    @AuraEnabled public DateTime lastHealthCheck { get; set; }
    @AuraEnabled public List<ComponentHealthStatus> componentHealth { get; set; }
    @AuraEnabled public List<SystemAlertSummary> recentAlerts { get; set; }
    @AuraEnabled public Map<String, Object> performanceMetrics { get; set; }
    @AuraEnabled public Map<String, Object> securityMetrics { get; set; }
    @AuraEnabled public List<String> recommendations { get; set; }
    @AuraEnabled public String healthTrend { get; set; }
    @AuraEnabled public Boolean requiresAttention { get; set; }
    
    public SystemHealthWrapper() {
        this.componentHealth = new List<ComponentHealthStatus>();
        this.recentAlerts = new List<SystemAlertSummary>();
        this.performanceMetrics = new Map<String, Object>();
        this.securityMetrics = new Map<String, Object>();
        this.recommendations = new List<String>();
        this.lastHealthCheck = DateTime.now();
        this.requiresAttention = false;
    }
}