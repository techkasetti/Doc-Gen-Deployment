// System Health Monitoring wrapper classes
public class SystemHealthSummary {
    
    @AuraEnabled
    public Decimal overallHealthScore { get; set; }
    
    @AuraEnabled
    public String healthStatus { get; set; }
    
    @AuraEnabled
    public Integer totalAlerts { get; set; }
    
    @AuraEnabled
    public Integer criticalAlerts { get; set; }
    
    @AuraEnabled
    public List<ComponentHealthStatus> componentHealth { get; set; }
    
    @AuraEnabled
    public Map<String, Object> kpis { get; set; }
    
    @AuraEnabled
    public List<String> topIssues { get; set; }
    
    @AuraEnabled
    public List<String> recommendations { get; set; }
    
    @AuraEnabled
    public DateTime lastUpdated { get; set; }
    
    @AuraEnabled
    public String executiveNarrative { get; set; }
    
    
    // Constructor
    public SystemHealthSummary() {
        this.componentHealth = new List<ComponentHealthStatus>();
        this.topIssues = new List<String>();
        this.recommendations = new List<String>();
        this.lastUpdated = DateTime.now();
    }
}
