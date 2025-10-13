 public class ComponentHealth {
        @AuraEnabled public String componentName { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Decimal healthScore { get; set; }
        @AuraEnabled public Decimal responseTime { get; set; }
        @AuraEnabled public String lastError { get; set; }
        @AuraEnabled public DateTime lastCheckTime { get; set; }
        
        public ComponentHealth() {
            this.healthScore = 0;
            this.responseTime = 0;
            this.lastCheckTime = DateTime.now();
        }
    }
