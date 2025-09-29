public class SystemMaintenanceResult {
    @AuraEnabled public Boolean success { get; set; }
    @AuraEnabled public String maintenanceType { get; set; }
    @AuraEnabled public List<String> completedActions { get; set; }
    @AuraEnabled public Map<String, Object> results { get; set; }
    @AuraEnabled public String message { get; set; }
    @AuraEnabled public DateTime executionTime { get; set; }
    @AuraEnabled public String error { get; set; }

    public SystemMaintenanceResult() {
        this.completedActions = new List<String>();
        this.results = new Map<String, Object>();
        this.executionTime = DateTime.now();
    }
}
