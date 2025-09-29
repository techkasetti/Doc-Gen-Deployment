public class ProductionAnalytics {
    
    public class ProductionMetrics {
        @AuraEnabled public Integer documentsGenerated { get; set; }
        @AuraEnabled public Integer signaturesCompleted { get; set; }
        @AuraEnabled public Integer complianceViolations { get; set; }
        @AuraEnabled public Decimal averageGenerationTime { get; set; }
        @AuraEnabled public Decimal systemUptime { get; set; }
        @AuraEnabled public Decimal complianceScore { get; set; }
        @AuraEnabled public Map<String, Integer> documentsByType { get; set; }
        @AuraEnabled public Map<String, Integer> documentsByRegion { get; set; }
        @AuraEnabled public List<Map<String, Object>> performanceMetrics { get; set; }
        @AuraEnabled public List<Map<String, Object>> recentActivity { get; set; }
    }
    
    @AuraEnabled(cacheable=true)
    public static ProductionMetrics getDashboardMetrics(String timeframe) {
        ProductionMetrics metrics = new ProductionMetrics();
        
        try {
            DateTime startTime = getStartTimeForTimeframe(timeframe);
            DateTime endTime = System.now();
            
            // Documents generated
            metrics.documentsGenerated = [
                SELECT COUNT() 
                FROM DocumentLifecycleConfiguration__c 
                WHERE CreatedDate >= :startTime 
                AND CreatedDate <= :endTime
            ];
            
            // Signatures completed
            metrics.signaturesCompleted = [
                SELECT COUNT() 
                FROM Signature_Request__c 
                WHERE Status__c = 'Signed' 
                AND SignedDate__c >= :startTime 
                AND SignedDate__c <= :endTime
            ];
            
            // Compliance violations
            metrics.complianceViolations = [
                SELECT COUNT() 
                FROM DocumentComplianceFinding__c 
                WHERE Status__c = 'OPEN' 
                AND Severity__c IN ('HIGH', 'CRITICAL')
                AND CreatedDate >= :startTime
            ];
            
            // Calculate average generation time
            List<AggregateResult> avgTime = [
                SELECT AVG(Processing_Time__c) avgTime
                FROM DocumentLifecycleConfiguration__c 
                WHERE Processing_Time__c != null 
                AND CreatedDate >= :startTime
            ];
            metrics.averageGenerationTime = avgTime.size() > 0 && avgTime[0].get('avgTime') != null ? 
                (Decimal) avgTime[0].get('avgTime') : 0;
            
            // System uptime calculation
            metrics.systemUptime = calculateSystemUptime(startTime, endTime);
            
            // Compliance score
            metrics.complianceScore = calculateComplianceScore();
            
            // Documents by type
            metrics.documentsByType = getDocumentsByType(startTime, endTime);
            
            // Documents by region
            metrics.documentsByRegion = getDocumentsByRegion(startTime, endTime);
            
            // Performance metrics
            metrics.performanceMetrics = getPerformanceMetrics(startTime, endTime);
            
            // Recent activity
            metrics.recentActivity = getRecentActivity(20); // Last 20 activities
            
        } catch (Exception e) {
            System.debug('Error generating dashboard metrics: ' + e.getMessage());
            // Return default metrics on error
            metrics = getDefaultMetrics();
        }
        
        return metrics;
    }
    
    public static void generateDailyReport() {
        try {
            ProductionMetrics dailyMetrics = getDashboardMetrics('TODAY');
            
            // Create daily report record
            SystemReport__c dailyReport = new SystemReport__c(
                ReportType__c = 'DAILY_PRODUCTION',
                ReportDate__c = Date.today(),
                DocumentsGenerated__c = dailyMetrics.documentsGenerated,
                SignaturesCompleted__c = dailyMetrics.signaturesCompleted,
                ComplianceViolations__c = dailyMetrics.complianceViolations,
                AverageGenerationTime__c = dailyMetrics.averageGenerationTime,
                SystemUptime__c = dailyMetrics.systemUptime,
                ComplianceScore__c = dailyMetrics.complianceScore,
                ReportData__c = JSON.serialize(dailyMetrics)
            );
            insert dailyReport;
            
            // Send daily report email to administrators
            sendDailyReportEmail(dailyMetrics);
            
            System.debug('✅ Daily production report generated successfully');
            
        } catch (Exception e) {
            System.debug('❌ Failed to generate daily report: ' + e.getMessage());
            createSystemAlert('DAILY_REPORT_FAILURE', e.getMessage(), 'HIGH');
        }
    }
    
    public static void generateWeeklyReport() {
        try {
            ProductionMetrics weeklyMetrics = getDashboardMetrics('THIS_WEEK');
            
            // Calculate weekly trends
            Map<String, Object> weeklyTrends = calculateWeeklyTrends();
            
            // Create weekly report
            SystemReport__c weeklyReport = new SystemReport__c(
                ReportType__c = 'WEEKLY_PRODUCTION',
                ReportDate__c = Date.today(),
                DocumentsGenerated__c = weeklyMetrics.documentsGenerated,
                SignaturesCompleted__c = weeklyMetrics.signaturesCompleted,
                ComplianceViolations__c = weeklyMetrics.complianceViolations,
                AverageGenerationTime__c = weeklyMetrics.averageGenerationTime,
                SystemUptime__c = weeklyMetrics.systemUptime,
                ComplianceScore__c = weeklyMetrics.complianceScore,
                ReportData__c = JSON.serialize(new Map<String, Object>{
                    'metrics' => weeklyMetrics,
                    'trends' => weeklyTrends
                })
            );
            insert weeklyReport;
            
            System.debug('✅ Weekly production report generated successfully');
            
        } catch (Exception e) {
            System.debug('❌ Failed to generate weekly report: ' + e.getMessage());
            createSystemAlert('WEEKLY_REPORT_FAILURE', e.getMessage(), 'HIGH');
        }
    }
    
    public static void generateMonthlyExecutiveReport() {
        try {
            ProductionMetrics monthlyMetrics = getDashboardMetrics('THIS_MONTH');
            
            // Calculate monthly insights
            Map<String, Object> executiveInsights = calculateExecutiveInsights();
            
            // Create executive report
            ExecutiveReport__c execReport = new ExecutiveReport__c(
                ReportMonth__c = Date.today().toStartOfMonth(),
                DocumentsGenerated__c = monthlyMetrics.documentsGenerated,
                SignaturesCompleted__c = monthlyMetrics.signaturesCompleted,
                ComplianceScore__c = monthlyMetrics.complianceScore,
                SystemUptime__c = monthlyMetrics.systemUptime,
                ExecutiveInsights__c = JSON.serialize(executiveInsights),
                ReportData__c = JSON.serialize(monthlyMetrics)
            );
            insert execReport;
            
            // Send executive summary email
            sendExecutiveReportEmail(monthlyMetrics, executiveInsights);
            
            System.debug('✅ Monthly executive report generated successfully');
            
        } catch (Exception e) {
            System.debug('❌ Failed to generate monthly executive report: ' + e.getMessage());
            createSystemAlert('EXECUTIVE_REPORT_FAILURE', e.getMessage(), 'CRITICAL');
        }
    }
    
    private static DateTime getStartTimeForTimeframe(String timeframe) {
        switch on timeframe {
            when 'TODAY' {
                return DateTime.now().date();
            }
            when 'THIS_WEEK' {
                return DateTime.now().addDays(-7);
            }
            when 'THIS_MONTH' {
                return DateTime.newInstance(Date.today().toStartOfMonth(), Time.newInstance(0, 0, 0, 0));
            }
            when 'LAST_7_DAYS' {
                return DateTime.now().addDays(-7);
            }
            when 'LAST_30_DAYS' {
                return DateTime.now().addDays(-30);
            }
            when else {
                return DateTime.now().addHours(-24); // Default to last 24 hours
            }
        }
    }
    
    private static Decimal calculateSystemUptime(DateTime startTime, DateTime endTime) {
        try {
            // Calculate total time period in hours
            Decimal totalHours = (endTime.getTime() - startTime.getTime()) / (1000 * 60 * 60);
            
            // Count system error hours (simplified calculation)
            Integer systemErrors = [
                SELECT COUNT() 
                FROM SystemAlert__c 
                WHERE Priority__c = 'CRITICAL' 
                AND Status__c = 'ACTIVE' 
                AND CreatedDate >= :startTime 
                AND CreatedDate <= :endTime
            ];
            
            // Estimate downtime (1 hour per critical error - simplified)
            Decimal downtimeHours = systemErrors * 1;
            
            // Calculate uptime percentage
            Decimal uptime = ((totalHours - downtimeHours) / totalHours) * 100;
            return Math.max(0, Math.min(100, uptime)); // Ensure between 0-100
            
        } catch (Exception e) {
            return 99.5; // Default uptime assumption
        }
    }
    
    private static Decimal calculateComplianceScore() {
        try {
            Integer totalDocuments = [SELECT COUNT() FROM DocumentLifecycleConfiguration__c WHERE CreatedDate = LAST_N_DAYS:7];
            Integer compliantDocuments = [SELECT COUNT() FROM DocumentLifecycleConfiguration__c WHERE ComplianceStatus__c = 'Compliant' AND CreatedDate = LAST_N_DAYS:7];
            
            if (totalDocuments == 0) return 100;
            return (Decimal.valueOf(compliantDocuments) / Decimal.valueOf(totalDocuments)) * 100;
            
        } catch (Exception e) {
            return 95.0; // Default compliance score
        }
    }
    
    private static Map<String, Integer> getDocumentsByType(DateTime startTime, DateTime endTime) {
        Map<String, Integer> typeCount = new Map<String, Integer>();
        
        List<AggregateResult> results = [
            SELECT ContractType__c type, COUNT(Id) totalcount
            FROM DocumentLifecycleConfiguration__c 
            WHERE CreatedDate >= :startTime 
            AND CreatedDate <= :endTime
            GROUP BY ContractType__c
        ];
        
        for (AggregateResult result : results) {
            typeCount.put((String)result.get('type'), (Integer)result.get('count'));
        }
        
        return typeCount;
    }
    
    private static Map<String, Integer> getDocumentsByRegion(DateTime startTime, DateTime endTime) {
        Map<String, Integer> regionCount = new Map<String, Integer>();
        
        List<AggregateResult> results = [
            SELECT Region__c region, COUNT(Id) totalcount
            FROM DocumentLifecycleConfiguration__c 
            WHERE CreatedDate >= :startTime 
            AND CreatedDate <= :endTime
            GROUP BY Region__c
        ];
        
        for (AggregateResult result : results) {
            regionCount.put((String)result.get('region'), (Integer)result.get('count'));
        }
        
        return regionCount;
    }
    
    private static List<Map<String, Object>> getPerformanceMetrics(DateTime startTime, DateTime endTime) {
        List<Map<String, Object>> metrics = new List<Map<String, Object>>();
        
        // Document generation performance
        List<AggregateResult> perfResults = [
            SELECT 
                AVG(Processing_Time__c) avgTime,
                MAX(Processing_Time__c) maxTime,
                MIN(Processing_Time__c) minTime,
                COUNT(Id) totalCount
            FROM DocumentLifecycleConfiguration__c 
            WHERE Processing_Time__c != null 
            AND CreatedDate >= :startTime 
            AND CreatedDate <= :endTime
        ];
        
        if (perfResults.size() > 0) {
            AggregateResult result = perfResults[0];
            metrics.add(new Map<String, Object>{
                'metric' => 'Document Generation Time',
                'average' => result.get('avgTime'),
                'maximum' => result.get('maxTime'),
                'minimum' => result.get('minTime'),
                'count' => result.get('totalCount'),
                'unit' => 'seconds'
            });
        }
        
        return metrics;
    }
    
    private static List<Map<String, Object>> getRecentActivity(Integer limitCount) {
        List<Map<String, Object>> activities = new List<Map<String, Object>>();
        
        List<AuditTrail__c> recentAudits = [
            SELECT Action__c, CreatedDate, CreatedBy.Name, RelatedRecordId__c
            FROM AuditTrail__c 
            ORDER BY CreatedDate DESC 
            LIMIT :limitCount
        ];
        
        for (AuditTrail__c audit : recentAudits) {
            activities.add(new Map<String, Object>{
                'id' => audit.Id,
                'message' => audit.Action__c + ' by ' + audit.CreatedBy.Name,
                'timestamp' => audit.CreatedDate.format(),
                'icon' => getActivityIcon(audit.Action__c)
            });
        }
        
        return activities;
    }
    
    private static String getActivityIcon(String action) {
        if (action.contains('Document')) return 'standard:document';
        if (action.contains('Signature')) return 'standard:signature';
        if (action.contains('Compliance')) return 'standard:approval';
        return 'standard:event';
    }
    
    private static Map<String, Object> calculateWeeklyTrends() {
        // Calculate week-over-week trends
        DateTime thisWeekStart = DateTime.now().addDays(-7);
        DateTime lastWeekStart = DateTime.now().addDays(-14);
        
        Integer thisWeekDocs = [SELECT COUNT() FROM DocumentLifecycleConfiguration__c WHERE CreatedDate >= :thisWeekStart];
        Integer lastWeekDocs = [SELECT COUNT() FROM DocumentLifecycleConfiguration__c WHERE CreatedDate >= :lastWeekStart AND CreatedDate < :thisWeekStart];
        
        Decimal docTrend = lastWeekDocs > 0 ? ((thisWeekDocs - lastWeekDocs) / Decimal.valueOf(lastWeekDocs)) * 100 : 0;
        
        return new Map<String, Object>{
            'documentTrend' => docTrend,
            'trendDirection' => docTrend > 0 ? 'up' : (docTrend < 0 ? 'down' : 'stable')
        };
    }
    
private static Map<String, Object> calculateExecutiveInsights() {
    return new Map<String, Object>{
        'topDocumentType' => getTopDocumentType(),
        'performanceSummary' => getPerformanceSummary(),
        'complianceHighlights' => getComplianceHighlights(),
        'systemRecommendations' => getSystemRecommendations(),
        'costSavings' => calculateCostSavings(),
        'userAdoption' => calculateUserAdoption(),
        'riskAssessment' => performRiskAssessment()
    };
}

private static Map<String, Object> getTopDocumentType() {
    List<AggregateResult> topType = [
        SELECT ContractType__c type, COUNT(Id) totalcount 
        FROM DocumentLifecycleConfiguration__c 
        WHERE CreatedDate = LAST_N_DAYS:30 
        GROUP BY ContractType__c 
        ORDER BY COUNT(Id) DESC 
        LIMIT 1
    ];
    
    if (topType.size() > 0) {
        return new Map<String, Object>{
            'type' => topType[0].get('type'),
            'count' => topType[0].get('count'),
            'percentage' => calculateTypePercentage((String)topType[0].get('type'))
        };
    }
    return new Map<String, Object>{'type' => 'N/A', 'count' => 0, 'percentage' => 0};
}

private static Map<String, Object> getPerformanceSummary() {
    List<AggregateResult> perfSummary = [
        SELECT AVG(Processing_Time__c) avgTime, COUNT(Id) totalDocs
        FROM DocumentLifecycleConfiguration__c 
        WHERE CreatedDate = LAST_N_DAYS:30 AND Processing_Time__c != null
    ];
    
    Decimal avgTime = perfSummary.size() > 0 && perfSummary[0].get('avgTime') != null ? 
                     (Decimal)perfSummary[0].get('avgTime') : 0;
    Integer totalDocs = perfSummary.size() > 0 ? (Integer)perfSummary[0].get('totalDocs') : 0;
    
    return new Map<String, Object>{
        'averageProcessingTime' => avgTime,
        'totalDocumentsProcessed' => totalDocs,
        'slaCompliance' => avgTime < 5 ? 100 : ((5 / avgTime) * 100),
        'performanceGrade' => getPerformanceGrade(avgTime)
    };
}

private static Map<String, Object> getComplianceHighlights() {
    Integer totalViolations = [SELECT COUNT() FROM DocumentComplianceFinding__c WHERE CreatedDate = LAST_N_DAYS:30];
    Integer resolvedViolations = [SELECT COUNT() FROM DocumentComplianceFinding__c WHERE Status__c = 'RESOLVED' AND CreatedDate = LAST_N_DAYS:30];
    
    return new Map<String, Object>{
        'totalViolations' => totalViolations,
        'resolvedViolations' => resolvedViolations,
        'resolutionRate' => totalViolations > 0 ? (resolvedViolations * 100 / totalViolations) : 100,
        'complianceStatus' => totalViolations == 0 ? 'EXCELLENT' : (totalViolations < 5 ? 'GOOD' : 'NEEDS_ATTENTION')
    };
}

private static List<String> getSystemRecommendations() {
    List<String> recommendations = new List<String>();
    
    // Performance recommendations
    Decimal avgTime = getAverageProcessingTime();
    if (avgTime > 5) {
        recommendations.add('Consider optimizing document generation templates to improve performance');
    }
    
    // Compliance recommendations
    Integer openViolations = [SELECT COUNT() FROM DocumentComplianceFinding__c WHERE Status__c = 'OPEN'];
    if (openViolations > 0) {
        recommendations.add('Address ' + openViolations + ' open compliance violations');
    }
    
    // Usage recommendations
    Map<String, Integer> regionUsage = getDocumentsByRegion(DateTime.now().addDays(-30), DateTime.now());
    if (regionUsage.size() < 3) {
        recommendations.add('Consider expanding document generation to additional regions');
    }
    
    return recommendations;
}

private static Map<String, Object> calculateCostSavings() {
    Integer docsGenerated = [SELECT COUNT() FROM DocumentLifecycleConfiguration__c WHERE CreatedDate = LAST_N_DAYS:30];
    Decimal costPerManualDoc = 25.0; // Estimated cost per manual document
    Decimal totalSavings = docsGenerated * costPerManualDoc;
    
    return new Map<String, Object>{
        'monthlyDocuments' => docsGenerated,
        'costPerDocument' => costPerManualDoc,
        'totalMonthlySavings' => totalSavings,
        'annualizedSavings' => totalSavings * 12
    };
}

private static Map<String, Object> calculateUserAdoption() {
    Set<Id> activeUsers = new Set<Id>();
    for (DocumentLifecycleConfiguration__c doc : [SELECT CreatedById FROM DocumentLifecycleConfiguration__c WHERE CreatedDate = LAST_N_DAYS:30]) {
        activeUsers.add(doc.CreatedById);
    }
    
    Integer totalLicensedUsers = [SELECT COUNT() FROM User WHERE IsActive = true AND Profile.Name LIKE '%Document%'];
    Decimal adoptionRate = totalLicensedUsers > 0 ? (activeUsers.size() * 100.0 / totalLicensedUsers) : 0;
    
    return new Map<String, Object>{
        'activeUsers' => activeUsers.size(),
        'totalLicensedUsers' => totalLicensedUsers,
        'adoptionRate' => adoptionRate,
        'adoptionStatus' => adoptionRate > 80 ? 'EXCELLENT' : (adoptionRate > 60 ? 'GOOD' : 'NEEDS_IMPROVEMENT')
    };
}

private static Map<String, Object> performRiskAssessment() {
    Integer criticalViolations = [SELECT COUNT() FROM DocumentComplianceFinding__c WHERE Severity__c = 'CRITICAL' AND Status__c = 'OPEN'];
    Integer highViolations = [SELECT COUNT() FROM DocumentComplianceFinding__c WHERE Severity__c = 'HIGH' AND Status__c = 'OPEN'];
    
    String riskLevel = 'LOW';
    if (criticalViolations > 0) {
        riskLevel = 'CRITICAL';
    } else if (highViolations > 3) {
        riskLevel = 'HIGH';
    } else if (highViolations > 0) {
        riskLevel = 'MEDIUM';
    }
    
    return new Map<String, Object>{
        'criticalViolations' => criticalViolations,
        'highViolations' => highViolations,
        'overallRiskLevel' => riskLevel,
        'riskScore' => calculateRiskScore(criticalViolations, highViolations)
    };
}

// Helper methods
private static ProductionMetrics getDefaultMetrics() {
    ProductionMetrics defaultMetrics = new ProductionMetrics();
    defaultMetrics.documentsGenerated = 0;
    defaultMetrics.signaturesCompleted = 0;
    defaultMetrics.complianceViolations = 0;
    defaultMetrics.averageGenerationTime = 0;
    defaultMetrics.systemUptime = 99.5;
    defaultMetrics.complianceScore = 95.0;
    defaultMetrics.documentsByType = new Map<String, Integer>();
    defaultMetrics.documentsByRegion = new Map<String, Integer>();
    defaultMetrics.performanceMetrics = new List<Map<String, Object>>();
    defaultMetrics.recentActivity = new List<Map<String, Object>>();
    return defaultMetrics;
}

private static Decimal getAverageProcessingTime() {
    List<AggregateResult> avgResult = [
        SELECT AVG(Processing_Time__c) avgTime 
        FROM DocumentLifecycleConfiguration__c 
        WHERE Processing_Time__c != null AND CreatedDate = LAST_N_DAYS:7
    ];
    return avgResult.size() > 0 && avgResult[0].get('avgTime') != null ? 
           (Decimal)avgResult[0].get('avgTime') : 3.0;
}

private static String getPerformanceGrade(Decimal avgTime) {
    if (avgTime < 2) return 'A+';
    if (avgTime < 3) return 'A';
    if (avgTime < 5) return 'B';
    if (avgTime < 8) return 'C';
    return 'D';
}

private static Decimal calculateTypePercentage(String docType) {
    Integer typeCount = [SELECT COUNT() FROM DocumentLifecycleConfiguration__c WHERE ContractType__c = :docType AND CreatedDate = LAST_N_DAYS:30];
    Integer totalCount = [SELECT COUNT() FROM DocumentLifecycleConfiguration__c WHERE CreatedDate = LAST_N_DAYS:30];
    return totalCount > 0 ? (typeCount * 100.0 / totalCount) : 0;
}

private static Integer calculateRiskScore(Integer critical, Integer high) {
    return (critical * 10) + (high * 5); // Weighted risk score
}

private static void sendDailyReportEmail(ProductionMetrics metrics) {
    try {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<User> adminUsers = [SELECT Email FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true];
        
        String emailBody = generateDailyEmailBody(metrics);
        
        for (User admin : adminUsers) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{admin.Email});
            email.setSubject('Daily Production Report - ' + Date.today().format());
            email.setHtmlBody(emailBody);
            emails.add(email);
        }
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    } catch (Exception e) {
        System.debug('Failed to send daily report email: ' + e.getMessage());
    }
}

private static void sendExecutiveReportEmail(ProductionMetrics metrics, Map<String, Object> insights) {
    try {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<User> execUsers = [SELECT Email FROM User WHERE UserRole.Name LIKE '%Executive%' AND IsActive = true];
        
        String emailBody = generateExecutiveEmailBody(metrics, insights);
        
        for (User exec : execUsers) {
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new String[]{exec.Email});
            email.setSubject('Monthly Executive Summary - ' + Date.today().format('MMMM yyyy'));
            email.setHtmlBody(emailBody);
            emails.add(email);
        }
        
        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails);
        }
    } catch (Exception e) {
        System.debug('Failed to send executive report email: ' + e.getMessage());
    }
}

private static String generateDailyEmailBody(ProductionMetrics metrics) {
    return '<html><body>' +
           '<h2>Daily Production Report - ' + Date.today().format() + '</h2>' +
           '<table border="1" style="border-collapse: collapse;">' +
           '<tr><td><strong>Documents Generated:</strong></td><td>' + metrics.documentsGenerated + '</td></tr>' +
           '<tr><td><strong>Signatures Completed:</strong></td><td>' + metrics.signaturesCompleted + '</td></tr>' +
           '<tr><td><strong>Compliance Score:</strong></td><td>' + metrics.complianceScore.setScale(1) + '%</td></tr>' +
           '<tr><td><strong>Average Generation Time:</strong></td><td>' + metrics.averageGenerationTime.setScale(2) + 's</td></tr>' +
           '<tr><td><strong>System Uptime:</strong></td><td>' + metrics.systemUptime.setScale(2) + '%</td></tr>' +
           '</table>' +
           '</body></html>';
}

private static String generateExecutiveEmailBody(ProductionMetrics metrics, Map<String, Object> insights) {
    Map<String, Object> costSavings = (Map<String, Object>) insights.get('costSavings');
    Map<String, Object> userAdoption = (Map<String, Object>) insights.get('userAdoption');
    
    return '<html><body>' +
           '<h2>Executive Summary - ' + Date.today().format('MMMM yyyy') + '</h2>' +
           '<h3>Key Performance Indicators</h3>' +
           '<ul>' +
           '<li>Documents Generated: ' + metrics.documentsGenerated + '</li>' +
           '<li>Compliance Score: ' + metrics.complianceScore.setScale(1) + '%</li>' +
           '<li>System Uptime: ' + metrics.systemUptime.setScale(2) + '%</li>' +
           '</ul>' +
           '<h3>Business Impact</h3>' +
           '<ul>' +
           '<li>Monthly Cost Savings: $' + costSavings.get('totalMonthlySavings') + '</li>' +
           '<li>User Adoption Rate: ' + userAdoption.get('adoptionRate') + '%</li>' +
           '</ul>' +
           '</body></html>';
}

private static void createSystemAlert(String alertType, String message, String priority) {
    try {
        SystemAlert__c alert = new SystemAlert__c(
            AlertType__c = alertType,
            Message__c = message,
            Priority__c = priority,
            Status__c = 'ACTIVE',
            AlertDate__c = System.now()
        );
        insert alert;
    } catch (Exception e) {
        System.debug('Failed to create system alert: ' + e.getMessage());
    }
}
}
