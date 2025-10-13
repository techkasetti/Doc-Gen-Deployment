// ProductionMonitoringService.cls
public class ProductionMonitoringService {
    
    // ====== DTO Classes ======
    public class HealthStatus {
        @AuraEnabled public String overallStatus { get; set; }
        @AuraEnabled public Decimal uptime { get; set; }
        @AuraEnabled public Integer totalGenerations { get; set; }
        @AuraEnabled public Integer successfulGenerations { get; set; }
        @AuraEnabled public Integer failedGenerations { get; set; }
        @AuraEnabled public Decimal errorRate { get; set; }
        @AuraEnabled public Decimal averageResponseTime { get; set; }
        @AuraEnabled public List<ComponentHealth> componentHealth { get; set; }
        @AuraEnabled public List<AlertSummary> activeAlerts { get; set; }
    }
    
    public class ComponentHealth {
        @AuraEnabled public String componentName { get; set; }
        @AuraEnabled public String status { get; set; }
        @AuraEnabled public Decimal responseTime { get; set; }
        @AuraEnabled public String lastChecked { get; set; }
    }
    
    public class AlertSummary {
        @AuraEnabled public String alertType { get; set; }
        @AuraEnabled public String severity { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public String timestamp { get; set; }
    }
    
    // ====== Main System Health ======
    @AuraEnabled(cacheable = true)
    public static HealthStatus getSystemHealthStatus() {
        HealthStatus health = new HealthStatus();
        
        try {
            // Calculate uptime
            DateTime systemStart = [
                SELECT CreatedDate 
                FROM System_Health_Monitor__c 
                WHERE Name = 'Production Health Monitor' 
                LIMIT 1
            ].CreatedDate;
            
            Decimal uptimeHours = (Datetime.now().getTime() - systemStart.getTime()) / (1000 * 60 * 60);
            health.uptime = uptimeHours;
            
            // Get generation statistics for last 24 hours
            DateTime last24Hours = Datetime.now().addHours(-24);
            List<Document_Generation_Audit__c> recentGenerations = [
                SELECT Id, Status__c, Processing_Time_Seconds__c 
                FROM Document_Generation_Audit__c 
                WHERE CreatedDate >= :last24Hours
            ];
            
            health.totalGenerations = recentGenerations.size();
            health.successfulGenerations = 0;
            health.failedGenerations = 0;
            Decimal totalResponseTime = 0;
            
            for (Document_Generation_Audit__c audit : recentGenerations) {
                if (audit.Status__c == 'SUCCESS') {
                    health.successfulGenerations++;
                } else {
                    health.failedGenerations++;
                }
                if (audit.Processing_Time_Seconds__c != null) {
                    totalResponseTime += audit.Processing_Time_Seconds__c;
                }
            }
            
            health.errorRate = health.totalGenerations > 0 
                ? (Decimal.valueOf(health.failedGenerations) / health.totalGenerations) * 100 
                : 0;
            health.averageResponseTime = health.totalGenerations > 0 
                ? totalResponseTime / health.totalGenerations 
                : 0;
            
            // Determine overall status
            if (health.errorRate > 10) {
                health.overallStatus = 'CRITICAL';
            } else if (health.errorRate > 5 || health.averageResponseTime > 30) {
                health.overallStatus = 'WARNING';
            } else {
                health.overallStatus = 'HEALTHY';
            }
            
            // Populate extra data
            health.componentHealth = getComponentHealthStatus();
            health.activeAlerts = getActiveAlerts();
            
        } catch (Exception e) {
            System.debug('Error getting health status: ' + e.getMessage());
            health.overallStatus = 'ERROR';
            health.uptime = 0;
            health.totalGenerations = 0;
            health.successfulGenerations = 0;
            health.failedGenerations = 0;
            health.errorRate = 100;
            health.averageResponseTime = 0;
            health.componentHealth = new List<ComponentHealth>();
            health.activeAlerts = new List<AlertSummary>();
        }
        
        return health;
    }
    
    // ====== Component Health ======
    private static List<ComponentHealth> getComponentHealthStatus() {
        List<ComponentHealth> components = new List<ComponentHealth>();
        
        try {
            // AI Models
            ComponentHealth aiModelHealth = new ComponentHealth();
            aiModelHealth.componentName = 'AI Models';
            aiModelHealth.lastChecked = Datetime.now().format();
            
            List<AI_Model_Configuration__c> activeModels = [
                SELECT Id, Name, Is_Active__c, Last_Health_Check__c, Response_Time_Ms__c 
                FROM AI_Model_Configuration__c 
                WHERE Is_Active__c = true
            ];
            
            if (activeModels.size() > 0) {
                aiModelHealth.status = 'HEALTHY';
                Decimal avgResponseTime = 0;
                for (AI_Model_Configuration__c model : activeModels) {
                    if (model.Response_Time_Ms__c != null) {
                        avgResponseTime += model.Response_Time_Ms__c;
                    }
                }
                aiModelHealth.responseTime = avgResponseTime / activeModels.size();
            } else {
                aiModelHealth.status = 'CRITICAL';
                aiModelHealth.responseTime = 0;
            }
            components.add(aiModelHealth);
            
            // Document Generation Engine
            ComponentHealth docGenHealth = new ComponentHealth();
            docGenHealth.componentName = 'Document Generation Engine';
            docGenHealth.lastChecked = Datetime.now().format();
            
            DateTime lastHour = Datetime.now().addHours(-1);
            List<Document_Generation_Audit__c> recentAudits = [
                SELECT Status__c, Processing_Time_Seconds__c
                FROM Document_Generation_Audit__c 
                WHERE CreatedDate >= :lastHour
                LIMIT 100
            ];
            
            if (recentAudits.size() > 0) {
                Integer successful = 0;
                Decimal totalTime = 0;
                for (Document_Generation_Audit__c audit : recentAudits) {
                    if (audit.Status__c == 'SUCCESS') {
                        successful++;
                    }
                    if (audit.Processing_Time_Seconds__c != null) {
                        totalTime += audit.Processing_Time_Seconds__c;
                    }
                }
                Decimal successRate = (Decimal.valueOf(successful) / recentAudits.size()) * 100;
                docGenHealth.responseTime = totalTime / recentAudits.size();
                
                if (successRate >= 95) {
                    docGenHealth.status = 'HEALTHY';
                } else if (successRate >= 85) {
                    docGenHealth.status = 'WARNING';
                } else {
                    docGenHealth.status = 'CRITICAL';
                }
            } else {
                docGenHealth.status = 'UNKNOWN';
                docGenHealth.responseTime = 0;
            }
            components.add(docGenHealth);
            
            // File Storage
            ComponentHealth storageHealth = new ComponentHealth();
            storageHealth.componentName = 'File Storage';
            storageHealth.lastChecked = Datetime.now().format();
            
            try {
                Integer recentFiles = [
                    SELECT COUNT() 
                    FROM ContentVersion 
                    WHERE CreatedDate = TODAY
                    LIMIT 1
                ];
                storageHealth.status = 'HEALTHY';
                storageHealth.responseTime = 100; // Mock
            } catch (Exception storageEx) {
                storageHealth.status = 'CRITICAL';
                storageHealth.responseTime = 0;
            }
            components.add(storageHealth);
            
        } catch (Exception e) {
            System.debug('Error getting component health: ' + e.getMessage());
        }
        
        return components;
    }
    
    // ====== Active Alerts ======
    private static List<AlertSummary> getActiveAlerts() {
        List<AlertSummary> alerts = new List<AlertSummary>();
        
        try {
            List<System_Alert__c> activeAlerts = [
                SELECT Alert_Type__c, Severity__c, Message__c, CreatedDate
                FROM System_Alert__c 
                WHERE Is_Active__c = true 
                AND CreatedDate >= :Datetime.now().addHours(-24)
                ORDER BY CreatedDate DESC
                LIMIT 10
            ];
            
            for (System_Alert__c alert : activeAlerts) {
                AlertSummary alertSummary = new AlertSummary();
                alertSummary.alertType = alert.Alert_Type__c;
                alertSummary.severity = alert.Severity__c;
                alertSummary.message = alert.Message__c;
                alertSummary.timestamp = alert.CreatedDate.format();
                alerts.add(alertSummary);
            }
        } catch (Exception e) {
            System.debug('Error getting active alerts: ' + e.getMessage());
        }
        
        return alerts;
    }
    
    // ====== Health Report ======
    @AuraEnabled
    public static String generateHealthReport() {
        try {
            HealthStatus health = getSystemHealthStatus();
            
            String report = '=== CONTEXT-AWARE DOCUMENT GENERATOR HEALTH REPORT ===\n';
            report += 'Generated: ' + Datetime.now().format() + '\n\n';
            
            report += 'OVERALL STATUS: ' + health.overallStatus + '\n';
            report += 'UPTIME: ' + health.uptime.setScale(2) + ' hours\n';
            report += 'ERROR RATE: ' + health.errorRate.setScale(2) + '%\n';
            report += 'AVERAGE RESPONSE TIME: ' + health.averageResponseTime.setScale(2) + ' seconds\n\n';
            
            report += 'GENERATION STATISTICS (Last 24 Hours):\n';
            report += '- Total Generations: ' + health.totalGenerations + '\n';
            report += '- Successful: ' + health.successfulGenerations + '\n';
            report += '- Failed: ' + health.failedGenerations + '\n\n';
            
            report += 'COMPONENT HEALTH STATUS:\n';
            for (ComponentHealth component : health.componentHealth) {
                report += '- ' + component.componentName + ': ' + component.status;
                if (component.responseTime != null && component.responseTime > 0) {
                    report += ' (Response Time: ' + component.responseTime.setScale(2) + 'ms)';
                }
                report += '\n';
            }
            
            report += '\nACTIVE ALERTS:\n';
            if (health.activeAlerts.isEmpty()) {
                report += '- No active alerts\n';
            } else {
                for (AlertSummary alert : health.activeAlerts) {
                    report += '- [' + alert.severity + '] ' + alert.alertType + ': ' 
                              + alert.message + ' (' + alert.timestamp + ')\n';
                }
            }
            
            // Recommendations
            report += '\nPERFORMANCE RECOMMENDATIONS:\n';
            if (health.errorRate > 5) {
                report += '- HIGH PRIORITY: Error rate above 5% - investigate failed generations\n';
            }
            if (health.averageResponseTime > 30) {
                report += '- MEDIUM PRIORITY: Response time above 30s - optimize document generation\n';
            }
            if (health.totalGenerations < 10) {
                report += '- INFO: Low generation volume in last 24 hours\n';
            }
            
            // System metrics
            report += '\nSYSTEM METRICS:\n';
            report += '- CPU Usage: ' + getCurrentCPUUsage() + '%\n';
            report += '- Memory Usage: ' + getCurrentMemoryUsage() + '%\n';
            report += '- API Calls Used: ' + Limits.getQueries() + '/' + Limits.getLimitQueries() + '\n';
            report += '- DML Statements Used: ' + Limits.getDMLStatements() + '/' + Limits.getLimitDMLStatements() + '\n';
            
            report += '\n=== END OF REPORT ===\n';
            
            return report;
            
        } catch (Exception e) {
            System.debug('Error generating health report: ' + e.getMessage());
            return 'Error generating health report: ' + e.getMessage();
        }
    }
    
    private static Decimal getCurrentCPUUsage() {
        return (Decimal.valueOf(Limits.getCpuTime()) / Limits.getLimitCpuTime()) * 100;
    }
    
    private static Decimal getCurrentMemoryUsage() {
        return (Decimal.valueOf(Limits.getHeapSize()) / Limits.getLimitHeapSize()) * 100;
    }
    
    // ====== Alert Management ======
    @AuraEnabled
    public static void acknowledgeAlert(String alertId) {
        try {
            System_Alert__c alert = [
                SELECT Id, Is_Active__c 
                FROM System_Alert__c 
                WHERE Id = :alertId 
                LIMIT 1
            ];
            alert.Is_Active__c = false;
            alert.Acknowledged_Date__c = Datetime.now();
            alert.Acknowledged_By__c = UserInfo.getUserId();
            update alert;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to acknowledge alert: ' + e.getMessage());
        }
    }
    
    // ====== Performance Metrics ======
    @AuraEnabled
    public static List<Map<String, Object>> getPerformanceMetrics(Integer days) {
        List<Map<String, Object>> metrics = new List<Map<String, Object>>();
        
        try {
            DateTime startDate = Datetime.now().addDays(-days);
            
                    // Total + Average Response Time (all records)
            List<AggregateResult> dailyStats = [
                SELECT DAY_ONLY(CreatedDate) day,
                    COUNT(Id) totalGenerations,
                    AVG(Processing_Time_Seconds__c) avgResponseTime
                FROM Document_Generation_Audit__c 
                WHERE CreatedDate >= :startDate
                GROUP BY DAY_ONLY(CreatedDate)
                ORDER BY DAY_ONLY(CreatedDate)
            ];

            // Successful generations only
            List<AggregateResult> successfulDailyStats = [
                SELECT DAY_ONLY(CreatedDate) day,
                    COUNT(Id) successfulGenerations
                FROM Document_Generation_Audit__c
                WHERE CreatedDate >= :startDate
                AND Status__c = 'SUCCESS'
                GROUP BY DAY_ONLY(CreatedDate)
                ORDER BY DAY_ONLY(CreatedDate)
            ];

            
            for (AggregateResult stat : dailyStats) {
                Map<String, Object> dayMetric = new Map<String, Object>();
                dayMetric.put('date', String.valueOf(stat.get('day')));
                dayMetric.put('totalGenerations', stat.get('totalGenerations'));
                dayMetric.put('successfulGenerations', stat.get('successfulGenerations'));
                dayMetric.put('avgResponseTime', stat.get('avgResponseTime'));
                
                Integer total = (Integer) stat.get('totalGenerations');
                Integer successful = (Integer) stat.get('successfulGenerations');
                Decimal successRate = total > 0 ? (Decimal.valueOf(successful) / total) * 100 : 0;
                dayMetric.put('successRate', successRate);
                
                metrics.add(dayMetric);
            }
        } catch (Exception e) {
            System.debug('Error getting performance metrics: ' + e.getMessage());
        }
        
        return metrics;
    }
}
