public class DocumentAnalyticsEngine {
       // Wrapper Classes
    public class DocumentAnalytics {
        @AuraEnabled public ViewMetrics viewMetrics { get; set; }
        @AuraEnabled public ComplianceMetrics complianceMetrics { get; set; }
        @AuraEnabled public CollaborationMetrics collaborationMetrics { get; set; }
        @AuraEnabled public PerformanceMetrics performanceMetrics { get; set; }
    }
     public class ViewMetrics {
        @AuraEnabled public Integer totalViews { get; set; }
        @AuraEnabled public Decimal averageDuration { get; set; }
        @AuraEnabled public Integer uniqueUsers { get; set; }
        @AuraEnabled public List<DocumentViewTracking__c> recentViews { get; set; }
    }
    
    public class ComplianceMetrics {
        @AuraEnabled public Decimal currentScore { get; set; }
        @AuraEnabled public Boolean gdprCompliant { get; set; }
        @AuraEnabled public Boolean hipaaCompliant { get; set; }
        @AuraEnabled public DateTime lastAnalysisDate { get; set; }
        @AuraEnabled public Decimal scoreTrend { get; set; }
        @AuraEnabled public List<DocumentComplianceTracking__c> complianceHistory { get; set; }
    }
        // Inner class for Analytics Report
    public class AnalyticsReport {
        @AuraEnabled public String reportId { get; set; }
        @AuraEnabled public String reportType { get; set; }
        @AuraEnabled public DateTime generatedAt { get; set; }
        @AuraEnabled public Map<String, Object> executiveSummary { get; set; }
        @AuraEnabled public Map<String, Object> performanceMetrics { get; set; }
        @AuraEnabled public Map<String, Object> complianceMetrics { get; set; }
        @AuraEnabled public Map<String, Object> usageAnalytics { get; set; }
        @AuraEnabled public Map<String, Object> trendAnalysis { get; set; }
        @AuraEnabled public List<AggregateResult> recommendations { get; set; }
    }

    
    // Inner class for Recommendation
    public class Recommendation {
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public String priority { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String impact { get; set; }
        @AuraEnabled public List<AggregateResult> actionItems { get; set; }
    }
    // Inner class for Usage Metrics
    public class UsageMetrics {
        @AuraEnabled public Integer totalDocuments { get; set; }
        @AuraEnabled public Integer aiGeneratedCount { get; set; }
        @AuraEnabled public Integer manualCount { get; set; }
        @AuraEnabled public Decimal aiAdoptionRate { get; set; }
        @AuraEnabled public Map<String, Integer> documentTypeBreakdown { get; set; }
        @AuraEnabled public Map<String, Integer> templateUsage { get; set; }
        @AuraEnabled public Map<String, Integer> userActivityBreakdown { get; set; }
    }

    public class CollaborationMetrics {
        @AuraEnabled public Integer totalCollaborators { get; set; }
        @AuraEnabled public Map<String, Integer> shareTypes { get; set; }
    }
    
    public class PerformanceMetrics {
        @AuraEnabled public Integer documentSize { get; set; }
        @AuraEnabled public DateTime createdDate { get; set; }
        @AuraEnabled public DateTime lastModifiedDate { get; set; }
        @AuraEnabled public Decimal estimatedProcessingTime { get; set; }
    }
public static Map<String, Object> computeDocumentMetrics(Id documentId) {
        Map<String,Object> out = new Map<String,Object>();
        out.put('views', 0);
        out.put('signatures', 0);
        return out;
    }

    @AuraEnabled(cacheable=true)
    public static DocumentAnalytics getDocumentAnalytics(Id documentId) {
        try {
            DocumentAnalytics analytics = new DocumentAnalytics();
            
            // Get view analytics
            analytics.viewMetrics = getViewMetrics(documentId);
            
            // Get compliance analytics
            analytics.complianceMetrics = getComplianceMetrics(documentId);
            
            // Get collaboration analytics
            analytics.collaborationMetrics = getCollaborationMetrics(documentId);
            
            // Get performance metrics
            analytics.performanceMetrics = getPerformanceMetrics(documentId);
            
            return analytics;
            
        } catch (Exception e) {
            throw new AuraHandledException('Analytics generation failed: ' + e.getMessage());
        }
    }  
    private static PerformanceMetrics getPerformanceMetrics(Id documentId) {
        PerformanceMetrics metrics = new PerformanceMetrics();
        
        // Get document size and processing metrics
        List<ContentDocument> docs = [
            SELECT ContentSize, CreatedDate, LastModifiedDate
            FROM ContentDocument 
            WHERE Id = :documentId
        ];
        
        if (!docs.isEmpty()) {
            ContentDocument doc = docs[0];
            metrics.documentSize = doc.ContentSize;
            metrics.createdDate = doc.CreatedDate;
            metrics.lastModifiedDate = doc.LastModifiedDate;
            
            // Calculate processing time estimate based on size
            metrics.estimatedProcessingTime = calculateProcessingTime(doc.ContentSize);
        }
        
        return metrics;
    }
      private static Decimal calculateProcessingTime(Integer contentSize) {
        // Base processing time calculation (simplified)
        Decimal baseTime = 2.0; // 2 seconds base
        Decimal sizeMultiplier = contentSize / 1000000.0; // Per MB
        return baseTime + (sizeMultiplier * 0.5);
    }
    
        private static CollaborationMetrics getCollaborationMetrics(Id documentId) {
        CollaborationMetrics metrics = new CollaborationMetrics();
        
        // Get collaborator count
        List<ContentDocumentLink> links = [
            SELECT LinkedEntityId, LinkedEntity.Type, ShareType
            FROM ContentDocumentLink 
            WHERE ContentDocumentId = :documentId
        ];
        
        metrics.totalCollaborators = links.size();
        metrics.shareTypes = new Map<String, Integer>();
        
        for (ContentDocumentLink link : links) {
            String shareType = link.ShareType;
            if (metrics.shareTypes.containsKey(shareType)) {
                metrics.shareTypes.put(shareType, metrics.shareTypes.get(shareType) + 1);
            } else {
                metrics.shareTypes.put(shareType, 1);
            }
        }
        
        return metrics;
    }
    
      private static ComplianceMetrics getComplianceMetrics(Id documentId) {
        ComplianceMetrics metrics = new ComplianceMetrics();
        
        List<DocumentComplianceTracking__c> complianceHistory = [
            SELECT Compliance_Score__c, GDPR_Compliant__c, HIPAA_Compliant__c, 
                   Analysis_Date__c
            FROM DocumentComplianceTracking__c 
            WHERE Document_ID__c = :documentId 
            ORDER BY Analysis_Date__c DESC
        ];
        
        if (!complianceHistory.isEmpty()) {
            DocumentComplianceTracking__c latest = complianceHistory[0];
            metrics.currentScore = latest.Compliance_Score__c;
            metrics.gdprCompliant = latest.GDPR_Compliant__c;
            metrics.hipaaCompliant = latest.HIPAA_Compliant__c;
            metrics.lastAnalysisDate = latest.Analysis_Date__c;
            
            // Calculate compliance trend
            if (complianceHistory.size() > 1) {
                Decimal previousScore = complianceHistory[1].Compliance_Score__c;
                metrics.scoreTrend = latest.Compliance_Score__c - previousScore;
            }
        }
        
        metrics.complianceHistory = complianceHistory;
        
        return metrics;
    }
    
    //     private static ViewMetrics getViewMetrics(Id documentId) {
    //     ViewMetrics metrics = new ViewMetrics();
        
    //     List<AggregateResult> viewStats = [
    //         SELECT COUNT(Id) totalViews, 
    //                AVG(Session_Duration__c) avgDuration,
    //                COUNT(DISTINCT User_ID__c) uniqueUsers
    //         FROM DocumentViewTracking__c 
    //         WHERE Document_ID__c = :documentId
    //     ];
        
    //     if (!viewStats.isEmpty()) {
    //         AggregateResult stats = viewStats[0];
    //         metrics.totalViews = (Integer)stats.get('totalViews');
    //         metrics.averageDuration = (Decimal)stats.get('avgDuration');
    //         metrics.uniqueUsers = (Integer)stats.get('uniqueUsers');
    //     }
        
    //     // Get recent view activity (last 7 days)
    //     metrics.recentViews = [
    //         SELECT User_ID__c, View_Date__c, Session_Duration__c
    //         FROM DocumentViewTracking__c 
    //         WHERE Document_ID__c = :documentId 
    //         AND View_Date__c >= :Date.today().addDays(-7)
    //         ORDER BY View_Date__c DESC
    //     ];
        
    //     return metrics;
    // }
        private static ViewMetrics getViewMetrics(Id documentId) {
        ViewMetrics metrics = new ViewMetrics();
        
        // First: get total views and average duration
        List<AggregateResult> viewStats = [
            SELECT COUNT(Id) totalViews, 
                AVG(Session_Duration__c) avgDuration
            FROM DocumentViewTracking__c 
            WHERE Document_ID__c = :documentId
        ];
        
        if (!viewStats.isEmpty()) {
            AggregateResult stats = viewStats[0];
            metrics.totalViews = (Integer)stats.get('totalViews');
            metrics.averageDuration = (Decimal)stats.get('avgDuration');
        }
        
        // Second: count unique users with GROUP BY
        List<AggregateResult> uniqueUserStats = [
            SELECT COUNT(Id) userCount
            FROM DocumentViewTracking__c
            WHERE Document_ID__c = :documentId
            GROUP BY User_ID__c
        ];
        metrics.uniqueUsers = uniqueUserStats.size();
        
        // Get recent view activity (last 7 days)
        metrics.recentViews = [
            SELECT User_ID__c, View_Date__c, Session_Duration__c
            FROM DocumentViewTracking__c 
            WHERE Document_ID__c = :documentId 
            AND View_Date__c >= :Date.today().addDays(-7)
            ORDER BY View_Date__c DESC
        ];
        
        return metrics;
    }

    // Main report generator
    @AuraEnabled(cacheable=true)
    public static AnalyticsReport generateComprehensiveReport(String reportType, Integer dayRange, String folderId) {
        try {
            AnalyticsReport report = new AnalyticsReport();
            report.reportId = generateReportId();
            report.reportType = reportType;
            report.generatedAt = DateTime.now();

            // switch (reportType) {
            //     case 'EXECUTIVE_SUMMARY':
            //         report = generateExecutiveSummaryReport(dayRange, folderId);
            //         break;
            //     case 'PERFORMANCE_ANALYSIS':
            //         report = generatePerformanceAnalysisReport(dayRange, folderId);
            //         break;
            //     case 'COMPLIANCE_REPORT':
            //         report = generateComplianceReport(dayRange, folderId);
            //         break;
            //     case 'USAGE_ANALYTICS':
            //         report = generateUsageAnalyticsReport(dayRange, folderId);
            //         break;
            //     default:
            //         report = generateExecutiveSummaryReport(dayRange, folderId);
            // }
            switch on reportType {
                when 'EXECUTIVE_SUMMARY' {
                    report = generateExecutiveSummaryReport(dayRange, folderId);
                }
                when 'PERFORMANCE_ANALYSIS' {
                    report = generatePerformanceAnalysisReport(dayRange, folderId);
                }
                when 'COMPLIANCE_REPORT' {
                    report = generateComplianceReport(dayRange, folderId);
                }
                when 'USAGE_ANALYTICS' {
                    report = generateUsageAnalyticsReport(dayRange, folderId);
                }
                when else {
                    report = generateExecutiveSummaryReport(dayRange, folderId);
                }
            }

            report.recommendations = generateRecommendations(report);
            return report;
        } catch (Exception e) {
            System.debug('Analytics report generation failed: ' + e.getMessage());
            throw new AuraHandledException('Failed to generate analytics report: ' + e.getMessage());
        }
    }
    private static List<Recommendation> generateRecommendations(AnalyticsReport report) {
        List<Recommendation> recommendations = new List<Recommendation>();

        // Performance Recommendation
        if (report.performanceMetrics != null) {
            Decimal avgTime = (Decimal) report.performanceMetrics.get('averageGenerationTime');
            if (avgTime != null && avgTime > 5.0) {
                Recommendation perfRec = new Recommendation();
                perfRec.category = 'PERFORMANCE';
                perfRec.priority = 'HIGH';
                perfRec.title = 'Optimize Document Generation Performance';
                perfRec.description = 'Average generation time of ' + avgTime.setScale(2) + ' seconds exceeds the 5-second SLA target.';
                perfRec.impact = 'Improving performance will enhance user experience and increase system capacity.';
                perfRec.actionItems = new List<String>{
                    'Analyze slow-performing templates and optimize them',
                    'Implement advanced caching strategies',
                    'Review AI model performance and consider optimization',
                    'Investigate database query performance'
                };
                recommendations.add(perfRec);
            }
        }

        // Compliance Recommendation
        if (report.complianceMetrics != null) {
            Decimal avgComplianceScore = (Decimal) report.complianceMetrics.get('averageComplianceScore');
            if (avgComplianceScore != null && avgComplianceScore < 95.0) {
                Recommendation complianceRec = new Recommendation();
                complianceRec.category = 'COMPLIANCE';
                complianceRec.priority = avgComplianceScore < 90 ? 'HIGH' : 'MEDIUM';
                complianceRec.title = 'Improve Compliance Standards';
                complianceRec.description = 'Average compliance score of ' + avgComplianceScore.setScale(1) + '% is below the 95% target.';
                complianceRec.impact = 'Enhanced compliance reduces legal risks and ensures regulatory adherence.';
                complianceRec.actionItems = new List<String>{
                    'Review and update compliance validation rules',
                    'Provide additional compliance training to users',
                    'Implement stricter pre-generation compliance checks',
                    'Conduct regular compliance audits'
                };
                recommendations.add(complianceRec);
            }
        }

        // Additional recommendation logic for usageAnalytics can be added here if needed

        return recommendations;
    }
      private static AnalyticsReport generateUsageAnalyticsReport(Integer dayRange, String folderId) {
        AnalyticsReport report = new AnalyticsReport();
        report.reportType = 'USAGE_ANALYTICS';

        DateTime startDate = DateTime.now().addDays(-dayRange);
        Map<String, Object> usageAnalytics = new Map<String, Object>();

        // Document Type Usage
        List<AggregateResult> documentTypeUsage = [
            SELECT Document_Type__c docType,
                COUNT(Id) generationCount,
                AVG(Generation_Time_Ms__c) avgTime,
                COUNT(DISTINCT (CreatedById)) uniqueUsers
            FROM Document_Generation_Log__c
            WHERE CreatedDate >= :startDate AND Document_Type__c != null
            GROUP BY Document_Type__c
            ORDER BY COUNT(Id) DESC
            LIMIT 10
        ];

        List<Map<String, Object>> documentTypeData = new List<Map<String, Object>>();
        Integer totalDocuments = 0;

        for (AggregateResult docTypeStats : documentTypeUsage) {
            Integer count = (Integer) docTypeStats.get('generationCount');

            Map<String, Object> docType = new Map<String, Object>();
            docType.put('type', (String) docTypeStats.get('docType'));
            docType.put('count', count);
            docType.put('averageTime', ((Decimal) docTypeStats.get('avgTime') / 1000).setScale(2));
            docType.put('uniqueUsers', (Integer) docTypeStats.get('uniqueUsers'));

            documentTypeData.add(docType);
            totalDocuments += count;
        }

        usageAnalytics.put('documentTypeBreakdown', documentTypeData);
        usageAnalytics.put('totalDocuments', totalDocuments);

        // User Activity Stats
        List<AggregateResult> userActivityStats = [
            SELECT CreatedById userId,
                COUNT(Id) documentCount,
                AVG(Generation_Time_Ms__c) avgTime,
                MAX(CreatedDate) lastActivity
            FROM Document_Generation_Log__c
            WHERE CreatedDate >= :startDate
            GROUP BY CreatedById
            ORDER BY COUNT(Id) DESC
            LIMIT 20
        ];

        List<Map<String, Object>> userActivityData = new List<Map<String, Object>>();
        Set<Id> userIds = new Set<Id>();

        for (AggregateResult userStats : userActivityStats) {
            userIds.add((Id) userStats.get('userId'));
        }

        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, Name, Email, Profile.Name
            FROM User
            WHERE Id IN :userIds
        ]);

        for (AggregateResult userStats : userActivityStats) {
            Id userId = (Id) userStats.get('userId');
            User user = userMap.get(userId);

            Map<String, Object> userActivity = new Map<String, Object>();
            userActivity.put('userName', user != null ? user.Name : 'Unknown User');
            userActivity.put('email', user != null ? user.Email : '');
            userActivity.put('profile', user != null ? user.Profile.Name : '');
            userActivity.put('documentCount', (Integer) userStats.get('documentCount'));
            userActivity.put('averageTime', ((Decimal) userStats.get('avgTime') / 1000).setScale(2));
            userActivity.put('lastActivity', (DateTime) userStats.get('lastActivity'));

            userActivityData.add(userActivity);
        }

        usageAnalytics.put('topUsers', userActivityData);

            List<AggregateResult> templateUsageStats = [
            SELECT Template_Name__c templateName,
                COUNT(Id) usageCount,
                AVG(Generation_Time_Ms__c) avgTime,
                COUNT_DISTINCT(CreatedById) uniqueUsers
            FROM Document_Generation_Log__c
            WHERE CreatedDate >= :startDate AND Template_Name__c != null
            GROUP BY Template_Name__c
            ORDER BY COUNT(Id) DESC
            LIMIT 15
            ];


        List<Map<String, Object>> templateUsageData = new List<Map<String, Object>>();

        for (AggregateResult templateStats : templateUsageStats) {
            Map<String, Object> template = new Map<String, Object>();
            template.put('name', (String) templateStats.get('templateName'));
            template.put('usageCount', (Integer) templateStats.get('usageCount'));
            template.put('averageTime', ((Decimal) templateStats.get('avgTime') / 1000).setScale(2));
            template.put('uniqueUsers', (Integer) templateStats.get('uniqueUsers'));

            templateUsageData.add(template);
        }

        usageAnalytics.put('templateUsage', templateUsageData);

        List<AggregateResult> dailyTrends = [
            SELECT DAY_ONLY(CreatedDate) activityDate,
                COUNT(Id) documentCount,
                AVG(Generation_Time_Ms__c) avgTime,
                COUNT_DISTINCT(CreatedById) activeUsers
            FROM Document_Generation_Log__c
            WHERE CreatedDate >= :startDate
            GROUP BY DAY_ONLY(CreatedDate)
            ORDER BY activityDate DESC
        ];



        List<Map<String, Object>> dailyTrendData = new List<Map<String, Object>>();

        for (AggregateResult dailyStats : dailyTrends) {
            Map<String, Object> dailyData = new Map<String, Object>();
            dailyData.put('date', (Date) dailyStats.get('activityDate'));
            dailyData.put('documentCount', (Integer) dailyStats.get('documentCount'));
            dailyData.put('averageTime', ((Decimal) dailyStats.get('avgTime') / 1000).setScale(2));
            dailyData.put('activeUsers', (Integer) dailyStats.get('activeUsers'));

            dailyTrendData.add(dailyData);
        }

        usageAnalytics.put('dailyTrends', dailyTrendData);

        // Final assembly
        report.usageAnalytics = usageAnalytics;
        return report;
    }

            // Performance Analysis Report
        private static AnalyticsReport generatePerformanceAnalysisReport(Integer dayRange, String folderId) {
            AnalyticsReport report = new AnalyticsReport();
            report.reportType = 'PERFORMANCE_ANALYSIS';
            DateTime startDate = DateTime.now().addDays(-dayRange);
            Map<String, Object> performanceMetrics = new Map<String, Object>();

            // Aggregate performance stats
            // List<AggregateResult> performanceStats = [
            //     SELECT MIN(Generation_Time_Ms__c) minTime, MAX(Generation_Time_Ms__c) maxTime, AVG(Generation_Time_Ms__c) avgTime, 
            //         PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY Generation_Time_Ms__c) p95Time, COUNT(Id) totalGenerations
            //     FROM Document_Generation_Log__c
            //     WHERE CreatedDate >= :startDate
            // ];
            List<AggregateResult> performanceStats = [
                SELECT
                MIN(Generation_Time_Ms__c) minTime,
                MAX(Generation_Time_Ms__c) maxTime,
                AVG(Generation_Time_Ms__c) avgTime,
                COUNT(Id) totalGenerations
                FROM Document_Generation_Log__c
                WHERE CreatedDate >= :startDate
            ];

            if (!performanceStats.isEmpty()) {
                AggregateResult perfStats = performanceStats[0];
                performanceMetrics.put('minimumGenerationTime', ((Decimal)perfStats.get('minTime') / 1000).setScale(3));
                performanceMetrics.put('maximumGenerationTime', ((Decimal)perfStats.get('maxTime') / 1000).setScale(3));
                performanceMetrics.put('averageGenerationTime', ((Decimal)perfStats.get('avgTime') / 1000).setScale(3));
                performanceMetrics.put('p95GenerationTime', ((Decimal)perfStats.get('p95Time') / 1000).setScale(3));
                performanceMetrics.put('totalGenerations', (Integer)perfStats.get('totalGenerations'));

                Decimal avgTime = (Decimal)perfStats.get('avgTime') / 1000;
                Decimal slaCompliance = avgTime <= 5.0 ? 100.0 : (5.0 / avgTime * 100);
                performanceMetrics.put('slaComplianceRate', slaCompliance.setScale(1));
            }

            // Hourly performance breakdown
            List<AggregateResult> hourlyPerformance = [
                SELECT HOUR_IN_DAY(CreatedDate) hourOfDay, AVG(Generation_Time_Ms__c) avgTime, COUNT(Id) requestCount
                FROM Document_Generation_Log__c
                WHERE CreatedDate >= :startDate
                GROUP BY HOUR_IN_DAY(CreatedDate)
                ORDER BY HOUR_IN_DAY(CreatedDate)
            ];
            List<Map<String, Object>> hourlyData = new List<Map<String, Object>>();
            for (AggregateResult hourlyStats : hourlyPerformance) {
                Map<String, Object> hourData = new Map<String, Object>();
                hourData.put('hour', (Integer)hourlyStats.get('hourOfDay'));
                hourData.put('averageTime', ((Decimal)hourlyStats.get('avgTime') / 1000).setScale(2));
                hourData.put('requestCount', (Integer)hourlyStats.get('requestCount'));
                hourlyData.add(hourData);
            }
            performanceMetrics.put('hourlyPerformanceBreakdown', hourlyData);

            // Template performance analysis
            // List templatePerformance = [
            //     SELECT Template_Name__c templateName, AVG(Generation_Time_Ms__c) avgTime, COUNT(Id) usageCount
            //     FROM Document_Generation_Log__c
            //     WHERE CreatedDate >= :startDate AND Template_Name__c != null
            //     GROUP BY Template_Name__c
            //     ORDER BY AVG(Generation_Time_Ms__c) DESC
            //     LIMIT 10
            // ];
            List<AggregateResult> templatePerformance = [
                SELECT Template_Name__c templateName,
                    AVG(Generation_Time_Ms__c) avgTime,
                    COUNT(Id) usageCount
                FROM Document_Generation_Log__c
                WHERE CreatedDate >= :startDate AND Template_Name__c != null
                GROUP BY Template_Name__c
                ORDER BY AVG(Generation_Time_Ms__c) DESC
                LIMIT 10
            ];

            List<Map<String, Object>> templateData = new List<Map<String, Object>>();
            for (AggregateResult templateStats : templatePerformance) {
                Map<String, Object> template = new Map<String, Object>();
                template.put('templateName', (String)templateStats.get('templateName'));
                template.put('averageTime', ((Decimal)templateStats.get('avgTime') / 1000).setScale(2));
                template.put('usageCount', (Integer)templateStats.get('usageCount'));
                templateData.add(template);
            }
            performanceMetrics.put('templatePerformanceAnalysis', templateData);

            report.performanceMetrics = performanceMetrics;
            return report;
        }
        
    // private static AnalyticsReport generateComplianceReport(Integer dayRange, String folderId) {
    //     AnalyticsReport report = new AnalyticsReport();
    //     report.reportType = 'COMPLIANCE_REPORT';

    //     DateTime startDate = DateTime.now().addDays(-dayRange);
    //     Map<String, Object> complianceMetrics = new Map<String, Object>();

    //     // Compliance Overview
    //     List<AggregateResult> complianceOverview = [
    //         SELECT
    //             COUNT(Id) totalChecks,
    //             AVG(Compliance_Score__c) avgScore,
    //             COUNT(CASE WHEN Compliance_Score__c >= 95 THEN 1 END) excellentCount,
    //             COUNT(CASE WHEN Compliance_Score__c >= 80 AND Compliance_Score__c < 95 THEN 1 END) goodCount,
    //             COUNT(CASE WHEN Compliance_Score__c < 80 THEN 1 END) poorCount
    //         FROM Compliance_Check_Log__c
    //         WHERE CreatedDate >= :startDate
    //     ];

    //     if (!complianceOverview.isEmpty()) {
    //         AggregateResult overview = complianceOverview[0];
    //         Integer total = (Integer) overview.get('totalChecks');

    //         complianceMetrics.put('totalComplianceChecks', total);
    //         complianceMetrics.put('averageComplianceScore', ((Decimal) overview.get('avgScore')).setScale(1));
    //         complianceMetrics.put('excellentRate', total > 0 ? ((Integer) overview.get('excellentCount') * 100.0 / total).setScale(1) : 0);
    //         complianceMetrics.put('goodRate', total > 0 ? ((Integer) overview.get('goodCount') * 100.0 / total).setScale(1) : 0);
    //         complianceMetrics.put('poorRate', total > 0 ? ((Integer) overview.get('poorCount') * 100.0 / total).setScale(1) : 0);
    //     }

    //     // Jurisdiction Breakdown
    //     List<AggregateResult> jurisdictionBreakdown = [
    //         SELECT
    //             Jurisdiction__c jurisdiction,
    //             COUNT(Id) checkCount,
    //             AVG(Compliance_Score__c) avgScore,
    //             COUNT(CASE WHEN Status__c = 'VIOLATION' THEN 1 END) violationCount
    //         FROM Compliance_Check_Log__c
    //         WHERE CreatedDate >= :startDate AND Jurisdiction__c != null
    //         GROUP BY Jurisdiction__c
    //         ORDER BY COUNT(Id) DESC
    //     ];

    //     List<Map<String, Object>> jurisdictionData = new List<Map<String, Object>>();
    //     for (AggregateResult jurisdictionStats : jurisdictionBreakdown) {
    //         Integer checkCount = (Integer) jurisdictionStats.get('checkCount');
    //         Integer violationCount = (Integer) jurisdictionStats.get('violationCount');

    //         Map<String, Object> jurisdiction = new Map<String, Object>();
    //         jurisdiction.put('name', (String) jurisdictionStats.get('jurisdiction'));
    //         jurisdiction.put('checkCount', checkCount);
    //         jurisdiction.put('averageScore', ((Decimal) jurisdictionStats.get('avgScore')).setScale(1));
    //         jurisdiction.put('violationCount', violationCount);
    //         jurisdiction.put('violationRate', checkCount > 0 ? (violationCount * 100.0 / checkCount).setScale(1) : 0);

    //         jurisdictionData.add(jurisdiction);
    //     }
    //     complianceMetrics.put('jurisdictionBreakdown', jurisdictionData);

    //     // Recent Violations
    //     List<Compliance_Violation__c> recentViolations = [
    //         SELECT Id, Violation_Type__c, Severity__c, Document_Type__c, CreatedDate, Description__c
    //         FROM Compliance_Violation__c
    //         WHERE CreatedDate >= :startDate
    //         ORDER BY CreatedDate DESC
    //         LIMIT 20
    //     ];

    //     List<Map<String, Object>> violationData = new List<Map<String, Object>>();
    //     for (Compliance_Violation__c violation : recentViolations) {
    //         Map<String, Object> violationInfo = new Map<String, Object>();
    //         violationInfo.put('type', violation.Violation_Type__c);
    //         violationInfo.put('severity', violation.Severity__c);
    //         violationInfo.put('documentType', violation.Document_Type__c);
    //         violationInfo.put('date', violation.CreatedDate.format('MM/dd/yyyy HH:mm'));
    //         violationInfo.put('description', violation.Description__c);

    //         violationData.add(violationInfo);
    //     }
    //     complianceMetrics.put('recentViolations', violationData);

    //     // Regulation Breakdown
    //     List<AggregateResult> regulationBreakdown = [
    //         SELECT
    //             Regulation_Type__c regulationType,
    //             COUNT(Id) checkCount,
    //             AVG(Compliance_Score__c) avgScore
    //         FROM Compliance_Check_Log__c
    //         WHERE CreatedDate >= :startDate AND Regulation_Type__c != null
    //         GROUP BY Regulation_Type__c
    //         ORDER BY COUNT(Id) DESC
    //     ];

    //     List<Map<String, Object>> regulationData = new List<Map<String, Object>>();
    //     for (AggregateResult regulationStats : regulationBreakdown) {
    //         Map<String, Object> regulation = new Map<String, Object>();
    //         regulation.put('type', (String) regulationStats.get('regulationType'));
    //         regulation.put('checkCount', (Integer) regulationStats.get('checkCount'));
    //         regulation.put('averageScore', ((Decimal) regulationStats.get('avgScore')).setScale(1));

    //         regulationData.add(regulation);
    //     }
    //     complianceMetrics.put('regulationBreakdown', regulationData);

    //     // Final assembly
    //     report.complianceMetrics = complianceMetrics;
    //     return report;
    // }

    private static AnalyticsReport generateComplianceReport(Integer dayRange, String folderId) {
        AnalyticsReport report = new AnalyticsReport();
        report.reportType = 'COMPLIANCE_REPORT';

        DateTime startDate = DateTime.now().addDays(-dayRange);
        Map<String, Object> complianceMetrics = new Map<String, Object>();

        // --- Compliance Overview ---
        List<AggregateResult> complianceOverview = [
            SELECT COUNT(Id) totalChecks, AVG(Compliance_Score__c) avgScore
            FROM Compliance_Check_Log__c
            WHERE CreatedDate >= :startDate
        ];

        // Separate queries for categories
        List<AggregateResult> excellentCountQuery = [
            SELECT COUNT(Id) cnt FROM Compliance_Check_Log__c
            WHERE CreatedDate >= :startDate AND Compliance_Score__c >= 95
        ];
        List<AggregateResult> goodCountQuery = [
            SELECT COUNT(Id) cnt FROM Compliance_Check_Log__c
            WHERE CreatedDate >= :startDate AND Compliance_Score__c >= 80 AND Compliance_Score__c < 95
        ];
        List<AggregateResult> poorCountQuery = [
            SELECT COUNT(Id) cnt FROM Compliance_Check_Log__c
            WHERE CreatedDate >= :startDate AND Compliance_Score__c < 80
        ];

        if (!complianceOverview.isEmpty()) {
            AggregateResult overview = complianceOverview[0];
            Integer total = (Integer) overview.get('totalChecks');
            Integer excellent = (Integer) excellentCountQuery[0].get('cnt');
            Integer good = (Integer) goodCountQuery[0].get('cnt');
            Integer poor = (Integer) poorCountQuery[0].get('cnt');

            complianceMetrics.put('totalComplianceChecks', total);
            complianceMetrics.put('averageComplianceScore', ((Decimal) overview.get('avgScore')).setScale(1));
            complianceMetrics.put('excellentRate', total > 0 ? (excellent * 100.0 / total).setScale(1) : 0);
            complianceMetrics.put('goodRate', total > 0 ? (good * 100.0 / total).setScale(1) : 0);
            complianceMetrics.put('poorRate', total > 0 ? (poor * 100.0 / total).setScale(1) : 0);
        }

        // --- Jurisdiction Breakdown ---
        List<AggregateResult> jurisdictionBreakdown = [
            SELECT Jurisdiction__c jurisdiction, COUNT(Id) checkCount, AVG(Compliance_Score__c) avgScore
            FROM Compliance_Check_Log__c
            WHERE CreatedDate >= :startDate AND Jurisdiction__c != null
            GROUP BY Jurisdiction__c
            ORDER BY COUNT(Id) DESC
        ];

        // Violations per jurisdiction
        List<AggregateResult> violationBreakdown = [
            SELECT Jurisdiction__c jurisdiction, COUNT(Id) violationCount
            FROM Compliance_Check_Log__c
            WHERE CreatedDate >= :startDate AND Jurisdiction__c != null AND Status__c = 'VIOLATION'
            GROUP BY Jurisdiction__c
        ];

        Map<String, Integer> violationMap = new Map<String, Integer>();
        for (AggregateResult v : violationBreakdown) {
            violationMap.put((String)v.get('jurisdiction'), (Integer)v.get('violationCount'));
        }

        List<Map<String, Object>> jurisdictionData = new List<Map<String, Object>>();
        for (AggregateResult j : jurisdictionBreakdown) {
            String jur = (String) j.get('jurisdiction');
            Integer checkCount = (Integer) j.get('checkCount');
            Decimal avgScore = ((Decimal) j.get('avgScore')).setScale(1);
            Integer violationCount = violationMap.containsKey(jur) ? violationMap.get(jur) : 0;
            Decimal violationRate = checkCount > 0 ? (violationCount * 100.0 / checkCount).setScale(1) : 0;

            Map<String, Object> jurisdiction = new Map<String, Object>();
            jurisdiction.put('name', jur);
            jurisdiction.put('checkCount', checkCount);
            jurisdiction.put('averageScore', avgScore);
            jurisdiction.put('violationCount', violationCount);
            jurisdiction.put('violationRate', violationRate);

            jurisdictionData.add(jurisdiction);
        }
        complianceMetrics.put('jurisdictionBreakdown', jurisdictionData);

        // --- Recent Violations ---
        List<Compliance_Violation__c> recentViolations = [
            SELECT Id, Violation_Type__c, Severity__c, Document_Type__c, CreatedDate, Description__c
            FROM Compliance_Violation__c
            WHERE CreatedDate >= :startDate
            ORDER BY CreatedDate DESC
            LIMIT 20
        ];

        List<Map<String, Object>> violationData = new List<Map<String, Object>>();
        for (Compliance_Violation__c violation : recentViolations) {
            Map<String, Object> violationInfo = new Map<String, Object>();
            violationInfo.put('type', violation.Violation_Type__c);
            violationInfo.put('severity', violation.Severity__c);
            violationInfo.put('documentType', violation.Document_Type__c);
            violationInfo.put('date', violation.CreatedDate.format('MM/dd/yyyy HH:mm'));
            violationInfo.put('description', violation.Description__c);
            violationData.add(violationInfo);
        }
        complianceMetrics.put('recentViolations', violationData);

        // --- Regulation Breakdown ---
        List<AggregateResult> regulationBreakdown = [
            SELECT Regulation_Type__c regulationType, COUNT(Id) checkCount, AVG(Compliance_Score__c) avgScore
            FROM Compliance_Check_Log__c
            WHERE CreatedDate >= :startDate AND Regulation_Type__c != null
            GROUP BY Regulation_Type__c
            ORDER BY COUNT(Id) DESC
        ];

        List<Map<String, Object>> regulationData = new List<Map<String, Object>>();
        for (AggregateResult regulationStats : regulationBreakdown) {
            Map<String, Object> regulation = new Map<String, Object>();
            regulation.put('type', (String) regulationStats.get('regulationType'));
            regulation.put('checkCount', (Integer) regulationStats.get('checkCount'));
            regulation.put('averageScore', ((Decimal) regulationStats.get('avgScore')).setScale(1));
            regulationData.add(regulation);
        }
        complianceMetrics.put('regulationBreakdown', regulationData);

        // --- Final assembly ---
        report.complianceMetrics = complianceMetrics;
        return report;
    }


        // Executive Summary Report
        private static AnalyticsReport generateExecutiveSummaryReport(Integer dayRange, String folderId) {
            AnalyticsReport report = new AnalyticsReport();
            report.reportType = 'EXECUTIVE_SUMMARY';
            DateTime startDate = DateTime.now().addDays(-dayRange);
            Map<String, Object> executiveSummary = new Map<String, Object>();

            // Document generation stats
            List<AggregateResult> documentStats = [
                SELECT COUNT(Id) totalDocs, COUNT_DISTINCT(CreatedById) uniqueUsers, AVG(Generation_Time_Ms__c) avgGenerationTime
                FROM Document_Generation_Log__c
                WHERE CreatedDate >= :startDate
            ];
            if (!documentStats.isEmpty()) {
                AggregateResult stats = documentStats[0];
                executiveSummary.put('totalDocumentsGenerated', (Integer)stats.get('totalDocs'));
                executiveSummary.put('uniqueActiveUsers', (Integer)stats.get('uniqueUsers'));
                executiveSummary.put('averageGenerationTime', ((Decimal)stats.get('avgGenerationTime') / 1000).setScale(2));
            }

            // Compliance stats
            // List<AggregateResult> complianceStats = [
            //     SELECT AVG(Compliance_Score__c) avgScore, COUNT_DISTINCT(CASE WHEN Compliance_Score__c >= 95 THEN Id END) excellentCount, COUNT(Id) totalChecks
            //     FROM Compliance_Check_Log__c
            //     WHERE CreatedDate >= :startDate
            // ];
            // Step 1: Aggregate basic stats
            List<AggregateResult> complianceStats = [
                SELECT
                    AVG(Compliance_Score__c) avgScore,
                    COUNT(Id) totalChecks
                FROM Compliance_Check_Log__c
                WHERE CreatedDate >= :startDate
            ];
            // Step 2: Count excellent scores separately
            Integer excellentCount = [
                SELECT COUNT()
                FROM Compliance_Check_Log__c
                WHERE CreatedDate >= :startDate AND Compliance_Score__c >= 95
            ];

            if (!complianceStats.isEmpty()) {
                AggregateResult compStats = complianceStats[0];
                Decimal avgScore = (Decimal)compStats.get('avgScore');
                Integer excellent = (Integer)compStats.get('excellentCount');
                Integer total = (Integer)compStats.get('totalChecks');
                executiveSummary.put('averageComplianceScore', avgScore?.setScale(1));
                executiveSummary.put('excellentComplianceRate', total > 0 ? (excellent * 100.0 / total).setScale(1) : 0);
            }

            // System health metrics
            SystemHealthMonitor.HealthMetrics healthMetrics = SystemHealthMonitor.getCurrentHealthMetrics();
            executiveSummary.put('systemUptime', healthMetrics.systemUptime);
            executiveSummary.put('currentSLA', healthMetrics.documentGenerationSLA);
            executiveSummary.put('activeUsers', healthMetrics.activeUsers);
            executiveSummary.put('errorRate', healthMetrics.errorRate);

            // Determine overall health status
            String overallHealthStatus = 'EXCELLENT';
            if (healthMetrics.documentGenerationSLA < 95 || healthMetrics.systemUptime < 99.5 || (Decimal)executiveSummary.get('averageComplianceScore') < 95) {
                overallHealthStatus = 'GOOD';
            }
            if (healthMetrics.documentGenerationSLA < 80 || healthMetrics.systemUptime < 99 || (Decimal)executiveSummary.get('averageComplianceScore') < 90) {
                overallHealthStatus = 'NEEDS_ATTENTION';
            }
            executiveSummary.put('overallHealthStatus', overallHealthStatus);

            report.executiveSummary = executiveSummary;
            return report;
        }

    public static ComprehensiveDocumentReport generateComprehensiveReport(String reportType, Map<String, Object> parameters) {
        ComprehensiveDocumentReport report = new ComprehensiveDocumentReport();
        report.reportType = reportType;
        report.generationStartTime = DateTime.now();
        report.parameters = parameters;
        
        try {
            switch on reportType {
                when 'LIFECYCLE_ANALYTICS' {
                    report = generateLifecycleAnalyticsReport(parameters);
                }
                when 'COMPLIANCE_DASHBOARD' {
                    report = generateComplianceDashboardReport(parameters);
                }
                when 'RETENTION_AUDIT' {
                    report = generateRetentionAuditReport(parameters);
                }
                when 'EXPIRATION_FORECAST' {
                    report = generateExpirationForecastReport(parameters);
                }
                when 'AI_INSIGHTS_SUMMARY' {
                    report = generateAIInsightsSummaryReport(parameters);
                }
                when 'RISK_ASSESSMENT' {
                    report = generateRiskAssessmentReport(parameters);
                }
                when else {
                    throw new ReportingException('Unsupported report type: ' + reportType);
                }
            }
            
            // Store report for future reference
            storeReportRecord(report);
            
            report.success = true;
            
        } catch (Exception e) {
            report.success = false;
            report.errorMessage = e.getMessage();
            report.stackTrace = e.getStackTraceString();
        }
        
        report.generationEndTime = DateTime.now();
        report.totalGenerationTime = report.generationEndTime.getTime() - report.generationStartTime.getTime();
        
        return report;
    }
    
    private static ComprehensiveDocumentReport generateLifecycleAnalyticsReport(Map<String, Object> parameters) {
        ComprehensiveDocumentReport report = new ComprehensiveDocumentReport();
        report.reportType = 'LIFECYCLE_ANALYTICS';
        
        try {
            // Document creation trends
            List<AggregateResult> creationTrends = [
                SELECT CALENDAR_MONTH(CreatedDate) month, 
                       CALENDAR_YEAR(CreatedDate) year,
                       COUNT(Id) documentCount,
                       AVG(ContentSize) avgSize
                FROM ContentDocument 
                WHERE CreatedDate = LAST_N_MONTHS:12
                GROUP BY CALENDAR_YEAR(CreatedDate), CALENDAR_MONTH(CreatedDate)
                ORDER BY CALENDAR_YEAR(CreatedDate) DESC, CALENDAR_MONTH(CreatedDate) DESC
            ];
            
            // Version control statistics
            List<AggregateResult> versionStats = [
                SELECT ContentDocumentId,
                       COUNT(Id) versionCount,
                       MAX(CreatedDate) lastModified
                FROM ContentVersion
                GROUP BY ContentDocumentId
                HAVING COUNT(Id) > 1
                ORDER BY COUNT(Id) DESC
                LIMIT 100
            ];
            
            // Archival statistics
            List<AggregateResult> archivalStats = [
                SELECT Archive_Status__c,
                       COUNT(Id) archivalCount,
                       AVG(Archive_Size_MB__c) avgArchiveSize
                FROM DocumentArchivalRecord__c
                WHERE Archival_Date__c = LAST_N_MONTHS:12
                GROUP BY Archive_Status__c
            ];
            
            // Expiration statistics
            List<AggregateResult> expirationStats = [
                SELECT Expiration_Status__c,
                       COUNT(Id) statusCount
                FROM DocumentExpirationTracking__c
                WHERE Last_Check_Date__c = LAST_N_DAYS:30
                GROUP BY Expiration_Status__c
            ];
            
            // Compile analytics data
            LifecycleAnalyticsData analyticsData = new LifecycleAnalyticsData();
            analyticsData.creationTrends = processCreationTrends(creationTrends);
            analyticsData.versioningMetrics = processVersioningMetrics(versionStats);
            analyticsData.archivalMetrics = processArchivalMetrics(archivalStats);
            analyticsData.expirationMetrics = processExpirationMetrics(expirationStats);
            analyticsData.totalDocuments = getTotalDocumentCount();
            analyticsData.activeDocuments = getActiveDocumentCount();
            analyticsData.archivedDocuments = getArchivedDocumentCount();
            analyticsData.expiredDocuments = getExpiredDocumentCount();
            
            report.analyticsData = analyticsData;
            report.visualizations = generateLifecycleVisualizations(analyticsData);
            
        } catch (Exception e) {
            report.errorMessage = 'Failed to generate lifecycle analytics: ' + e.getMessage();
            throw e;
        }
        
        return report;
    }
    
    // Advanced AI-Powered Document Intelligence Enhancement
    @future(callout=true)
    public static void enhanceDocumentIntelligence(Set<Id> documentIds) {
        for (Id docId : documentIds) {
            try {
                EnhancementResult result = executeIntelligenceEnhancement(docId);
                logEnhancementResult(docId, result);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Intelligence enhancement failed for ' + docId + ': ' + e.getMessage());
                createEnhancementErrorLog(docId, e);
            }
        }
    }
    
    private static EnhancementResult executeIntelligenceEnhancement(Id documentId) {
        EnhancementResult result = new EnhancementResult();
        result.documentId = documentId;
        result.enhancementStartTime = DateTime.now();
        
        try {
            // Get latest document version
            ContentVersion version = [
                SELECT Id, ContentDocumentId, VersionData, Title, FileType, ContentSize
                FROM ContentVersion 
                WHERE ContentDocumentId = :documentId AND IsLatest = true
                LIMIT 1
            ];
            
            // Extract and analyze content
            String documentText = extractDocumentText(version);
            
            // Enhanced semantic analysis
            SemanticAnalysisResult semanticResult = performEnhancedSemanticAnalysis(documentText);
            result.semanticAnalysis = semanticResult;
            
            // Advanced entity extraction
            EntityExtractionResult entityResult = extractAdvancedEntities(documentText);
            result.entityExtraction = entityResult;
            
            // Compliance pattern recognition
            CompliancePatternResult complianceResult = recognizeCompliancePatterns(documentText, semanticResult);
            result.compliancePatterns = complianceResult;
            
            // Risk factor identification
            RiskFactorResult riskResult = identifyAdvancedRiskFactors(documentText, entityResult, complianceResult);
            result.riskFactors = riskResult;
            
            // Generate enhanced metadata
            EnhancedMetadata metadata = generateEnhancedMetadata(semanticResult, entityResult, complianceResult, riskResult);
            result.enhancedMetadata = metadata;
            
            // Store enhanced intelligence data
            storeEnhancedIntelligence(documentId, result);
            
            // Update document classification
            updateAdvancedDocumentClassification(documentId, metadata);
            
            // Trigger automated workflows if needed
            if (result.requiresAutomatedAction) {
                triggerAutomatedWorkflows(documentId, result);
            }
            
            result.success = true;
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
            result.stackTrace = e.getStackTraceString();
        }
        
        result.enhancementEndTime = DateTime.now();
        result.totalEnhancementTime = result.enhancementEndTime.getTime() - result.enhancementStartTime.getTime();
        
        return result;
    }
}
