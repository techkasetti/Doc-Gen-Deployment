public class ComponentHealthStatus{
    @AuraEnabled public String componentName { get; set; }
    @AuraEnabled public String status { get; set; }
    @AuraEnabled public Decimal healthScore { get; set; }
    @AuraEnabled public DateTime lastChecked { get; set; }
    @AuraEnabled public String statusMessage { get; set; }
    @AuraEnabled public Decimal responseTime { get; set; }
    @AuraEnabled public String version { get; set; }
    @AuraEnabled public Boolean isOperational { get; set; }
    
    public ComponentHealthStatus(String name, String status, Decimal score) {
        this.componentName = name;
        this.status = status;
        this.healthScore = score;
        this.lastChecked = DateTime.now();
        this.isOperational = (status == 'HEALTHY' || status == 'OPERATIONAL');
    }
}