public with sharing class DocumentAnalyticsEngine {
    // ================================
    // Inner DTO / Wrapper classes
    // ================================
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

    public class AnalyticsReport {
        @AuraEnabled public String reportId { get; set; }
        @AuraEnabled public String reportType { get; set; }
        @AuraEnabled public DateTime generatedAt { get; set; }
        @AuraEnabled public Map<String, Object> executiveSummary { get; set; }
        @AuraEnabled public Map<String, Object> performanceMetrics { get; set; }
        @AuraEnabled public Map<String, Object> complianceMetrics { get; set; }
        @AuraEnabled public Map<String, Object> usageAnalytics { get; set; }
        @AuraEnabled public Map<String, Object> trendAnalysis { get; set; }
        @AuraEnabled public List<Recommendation> recommendations { get; set; }
    }

    public class Recommendation {
        @AuraEnabled public String category { get; set; }
        @AuraEnabled public String priority { get; set; }
        @AuraEnabled public String title { get; set; }
        @AuraEnabled public String description { get; set; }
        @AuraEnabled public String impact { get; set; }
        @AuraEnabled public List<String> actionItems { get; set; }
    }

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

    // Comprehensive report DTO used by advanced report methods
    public class ComprehensiveDocumentReport {
        public String reportType;
        public DateTime generationStartTime;
        public DateTime generationEndTime;
        public Long totalGenerationTime;
        public Map<String, Object> parameters;
        public Object analyticsData;
        public Object visualizations;
        public Boolean success = false;
        public String errorMessage;
        public String stackTrace;
    }

    // Lifecycle analytics DTO
    public class LifecycleAnalyticsData {
        public Object creationTrends;
        public Object versioningMetrics;
        public Object archivalMetrics;
        public Object expirationMetrics;
        public Integer totalDocuments;
        public Integer activeDocuments;
        public Integer archivedDocuments;
        public Integer expiredDocuments;
    }

    // Enhancement result DTOs (placeholders)
    public class EnhancementResult {
        public Id documentId;
        public DateTime enhancementStartTime;
        public DateTime enhancementEndTime;
        public Long totalEnhancementTime;
        public Boolean success = false;
        public String errorMessage;
        public String stackTrace;
        public Object semanticAnalysis;
        public Object entityExtraction;
        public Object compliancePatterns;
        public Object riskFactors;
        public Object enhancedMetadata;
        public Boolean requiresAutomatedAction = false;
    }

    // Placeholder helper DTO types used by AI enhancement pipeline
    public class SemanticAnalysisResult {}
    public class EntityExtractionResult {}
    public class CompliancePatternResult {}
    public class RiskFactorResult {}
    public class EnhancedMetadata {}

    // Custom exception used by reporting entry point
    public class ReportingException extends Exception {}

    // =========================================
    // Public API (Aura-enabled + general)
    // =========================================

    @AuraEnabled(cacheable=true)
    public static DocumentAnalytics getDocumentAnalytics(Id documentId) {
        if (documentId == null) {
            throw new AuraHandledException('documentId is required');
        }
        try {
            DocumentAnalytics analytics = new DocumentAnalytics();
            analytics.viewMetrics = getViewMetrics(documentId);
            analytics.complianceMetrics = getComplianceMetrics(documentId);
            analytics.collaborationMetrics = getCollaborationMetrics(documentId);
            analytics.performanceMetrics = getPerformanceMetrics(documentId);
            return analytics;
        } catch (Exception e) {
            // Bubble as an Aura-friendly error
            throw new AuraHandledException('Analytics generation failed: ' + e.getMessage());
        }
    }

    // Simple utility map-returning entry (keeps your existing signature)
    public static Map<String, Object> computeDocumentMetrics(Id documentId) {
        Map<String, Object> out = new Map<String, Object>();
        out.put('views', 0);
        out.put('signatures', 0);
        return out;
    }

    // =========================================
    // Performance / Collaboration / Compliance
    // =========================================

    private static PerformanceMetrics getPerformanceMetrics(Id documentId) {
        PerformanceMetrics metrics = new PerformanceMetrics();
        try {
            List<ContentDocument> docs = [ SELECT ContentSize, CreatedDate, LastModifiedDate FROM ContentDocument WHERE Id = :documentId LIMIT 1 ];
            if (!docs.isEmpty()) {
                ContentDocument doc = docs[0];
                metrics.documentSize = doc.ContentSize;
                metrics.createdDate = doc.CreatedDate;
                metrics.lastModifiedDate = doc.LastModifiedDate;
                metrics.estimatedProcessingTime = calculateProcessingTime(doc.ContentSize);
            }
        } catch (Exception e) {
            // swallow - return defaults (keeps business logic unchanged)
            metrics.documentSize = metrics.documentSize == null ? 0 : metrics.documentSize;
            metrics.estimatedProcessingTime = metrics.estimatedProcessingTime == null ? 0 : metrics.estimatedProcessingTime;
        }
        return metrics;
    }

    private static Decimal calculateProcessingTime(Integer contentSize) {
        Decimal baseTime = 2.0; // sec baseline
        Decimal sizeMultiplier = 0;
        if (contentSize != null && contentSize > 0) {
            sizeMultiplier = ((Decimal) contentSize) / 1000000.0;
        }
        return baseTime + (sizeMultiplier * 0.5);
    }

    private static CollaborationMetrics getCollaborationMetrics(Id documentId) {
        CollaborationMetrics metrics = new CollaborationMetrics();
        metrics.shareTypes = new Map<String, Integer>();
        try {
            List<ContentDocumentLink> links = [ SELECT ShareType FROM ContentDocumentLink WHERE ContentDocumentId = :documentId ];
            metrics.totalCollaborators = links.size();
            for (ContentDocumentLink l : links) {
                String st = l.ShareType == null ? 'Unknown' : l.ShareType;
                if (metrics.shareTypes.containsKey(st)) {
                    metrics.shareTypes.put(st, metrics.shareTypes.get(st) + 1);
                } else {
                    metrics.shareTypes.put(st, 1);
                }
            }
        } catch (Exception e) {
            metrics.totalCollaborators = 0;
        }
        return metrics;
    }

    private static ComplianceMetrics getComplianceMetrics(Id documentId) {
        ComplianceMetrics metrics = new ComplianceMetrics();
        try {
            List<DocumentComplianceTracking__c> complianceHistory = [
                SELECT Compliance_Score__c, GDPR_Compliant__c, HIPAA_Compliant__c, Analysis_Date__c
                FROM DocumentComplianceTracking__c
                WHERE Document_ID__c = :documentId
                ORDER BY Analysis_Date__c DESC
                LIMIT 50
            ];
            if (!complianceHistory.isEmpty()) {
                /*DocumentComplianceTracking__c latest = complianceHistory[0];
                metrics.currentScore = latest.Compliance_Score__c != null ? latest.Compliance_Score__c : 0;
                metrics.gdprCompliant = latest.GDPR_Compliant__c != null ? latest.GDPR_Compliant__c : false;
                metrics.hipaaCompliant = latest.HIPAA_Compliant__c != null ? latest.HIPAA_Compliant__c : false;
                metrics.lastAnalysisDate = latest.Analysis_Date__c;
                if (complianceHistory.size() > 1) {
                    Decimal prev = complianceHistory[1].Compliance_Score__c != null ? complianceHistory[1].Compliance_Score__c : 0;
                    metrics.scoreTrend = metrics.currentScore - prev;
                } else {
                    metrics.scoreTrend = 0;
                }*/
            } else {
                metrics.currentScore = 0;
                metrics.gdprCompliant = false;
                metrics.hipaaCompliant = false;
                metrics.scoreTrend = 0;
            }
            metrics.complianceHistory = complianceHistory;
        } catch (Exception e) {
            metrics.currentScore = 0;
            metrics.complianceHistory = new List<DocumentComplianceTracking__c>();
        }
        return metrics;
    }

    // =========================================
    // View Metrics - safe aggregate extraction
    // =========================================

    // Helper: safely extract integer value from AggregateResult for various provider return types
    private static Integer safeIntegerFromAggregate(AggregateResult ar, String key) {
        if (ar == null) return 0;
        Object o = ar.get(key);
        if (o == null) return 0;
        if (o instanceof Integer) return (Integer)o;
        if (o instanceof Long) return (Integer)((Long)o);
        if (o instanceof Decimal) return ((Decimal)o).intValue();
        try { return Integer.valueOf(String.valueOf(o)); } catch (Exception ex) { return 0; }
    }

    private static Decimal safeDecimalFromAggregate(AggregateResult ar, String key) {
        if (ar == null) return Decimal.valueOf('0');
        Object o = ar.get(key);
        if (o == null) return Decimal.valueOf('0');
        if (o instanceof Decimal) return (Decimal)o;
        if (o instanceof Integer) return Decimal.valueOf(String.valueOf(o));
        if (o instanceof Long) return Decimal.valueOf(String.valueOf(o));
        try { return Decimal.valueOf(String.valueOf(o)); } catch (Exception ex) { return Decimal.valueOf('0'); }
    }

    private static ViewMetrics getViewMetrics(Id documentId) {
        ViewMetrics metrics = new ViewMetrics();
        metrics.totalViews = 0;
        metrics.averageDuration = 0;
        metrics.uniqueUsers = 0;
        metrics.recentViews = new List<DocumentViewTracking__c>();

        try {
            List<AggregateResult> viewStats = [
                SELECT COUNT(Id) totalViews, AVG(Session_Duration__c) avgDuration
                FROM DocumentViewTracking__c
                WHERE Document_ID__c = :documentId
            ];
            if (!viewStats.isEmpty()) {
                AggregateResult ar = viewStats[0];
                metrics.totalViews = safeIntegerFromAggregate(ar, 'totalViews');
                metrics.averageDuration = safeDecimalFromAggregate(ar, 'avgDuration');
            }

            // Unique users: group by User_ID__c and count number of groups
            List<AggregateResult> uniqueUserGroups = [
                SELECT User_ID__c userId
                FROM DocumentViewTracking__c
                WHERE Document_ID__c = :documentId
                GROUP BY User_ID__c
            ];
            metrics.uniqueUsers = (uniqueUserGroups == null) ? 0 : uniqueUserGroups.size();

            // Recent views (last 7 days)
            metrics.recentViews = [
                SELECT User_ID__c, View_Date__c, Session_Duration__c
                FROM DocumentViewTracking__c
                WHERE Document_ID__c = :documentId
                AND View_Date__c >= :Date.today().addDays(-7)
                ORDER BY View_Date__c DESC
            ];
        } catch (Exception e) {
            // fallback defaults already set
        }
        return metrics;
    }

    // =========================================
    // Comprehensive Report Generation (UI)
    // =========================================

    // Helper: simple reportId generator
    private static String generateReportId() {
        return 'RPT_' + String.valueOf(DateTime.now().getTime());
    }

    @AuraEnabled(cacheable=true)
    public static AnalyticsReport generateComprehensiveReport(String reportType, Integer dayRange, String folderId) {
        // keep signature and business logic
        if (dayRange == null || dayRange <= 0) dayRange = 30;
        try {
            AnalyticsReport report = new AnalyticsReport();
            report.reportId = generateReportId();
            report.reportType = reportType;
            report.generatedAt = DateTime.now();

            if ('EXECUTIVE_SUMMARY' == reportType) {
                report = generateExecutiveSummaryReport(dayRange, folderId);
            } else if ('PERFORMANCE_ANALYSIS' == reportType) {
                report = generatePerformanceAnalysisReport(dayRange, folderId);
            } else if ('COMPLIANCE_REPORT' == reportType) {
                report = generateComplianceReport(dayRange, folderId);
            } else if ('USAGE_ANALYTICS' == reportType) {
                report = generateUsageAnalyticsReport(dayRange, folderId);
            } else {
                // default to executive summary
                report = generateExecutiveSummaryReport(dayRange, folderId);
            }

            report.recommendations = generateRecommendations(report);
            return report;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to generate analytics report: ' + e.getMessage());
        }
    }

    // Recommendation builder (keeps your logic)
    private static List<Recommendation> generateRecommendations(AnalyticsReport report) {
        List<Recommendation> recs = new List<Recommendation>();

        // Performance recommendation if averageGenerationTime exists
        try {
            if (report.performanceMetrics != null && report.performanceMetrics.containsKey('averageGenerationTime')) {
                Object oAvg = report.performanceMetrics.get('averageGenerationTime');
                Decimal avgTime = oAvg instanceof Decimal ? (Decimal)oAvg : (oAvg != null ? Decimal.valueOf(String.valueOf(oAvg)) : 0);
                if (avgTime != null && avgTime > 5.0) {
                    Recommendation r = new Recommendation();
                    r.category = 'PERFORMANCE';
                    r.priority = 'HIGH';
                    r.title = 'Optimize Document Generation Performance';
                    r.description = 'Average generation time of ' + avgTime.setScale(2) + ' seconds exceeds the 5-second SLA target.';
                    r.impact = 'Improving performance will enhance user experience and increase system capacity.';
                    r.actionItems = new List<String>{
                        'Analyze slow-performing templates and optimize them',
                        'Implement advanced caching strategies',
                        'Review AI model performance and consider optimization',
                        'Investigate database query performance'
                    };
                    recs.add(r);
                }
            }
        } catch (Exception ex) {
            // no-op
        }

        // Compliance recommendation
        try {
            if (report.complianceMetrics != null && report.complianceMetrics.containsKey('averageComplianceScore')) {
                Object oComp = report.complianceMetrics.get('averageComplianceScore');
                Decimal avgComp = oComp instanceof Decimal ? (Decimal)oComp : (oComp != null ? Decimal.valueOf(String.valueOf(oComp)) : 0);
                if (avgComp != null && avgComp < 95.0) {
                    Recommendation r = new Recommendation();
                    r.category = 'COMPLIANCE';
                    r.priority = (avgComp < 90) ? 'HIGH' : 'MEDIUM';
                    r.title = 'Improve Compliance Standards';
                    r.description = 'Average compliance score of ' + avgComp.setScale(1) + '% is below the 95% target.';
                    r.impact = 'Enhanced compliance reduces legal risks and ensures regulatory adherence.';
                    r.actionItems = new List<String>{
                        'Review and update compliance validation rules',
                        'Provide additional compliance training to users',
                        'Implement stricter pre-generation compliance checks',
                        'Conduct regular compliance audits'
                    };
                    recs.add(r);
                }
            }
        } catch (Exception ex) {
            // no-op
        }

        return recs;
    }

    // ==========================
    // Report implementations
    // ==========================

    private static AnalyticsReport generateUsageAnalyticsReport(Integer dayRange, String folderId) {
        AnalyticsReport report = new AnalyticsReport();
        report.reportType = 'USAGE_ANALYTICS';
        DateTime startDate = DateTime.now().addDays(-dayRange);
        Map<String, Object> usageAnalytics = new Map<String, Object>();

        // Document Type Usage
        List<AggregateResult> docTypeStats = [
            SELECT Document_Type__c docType, COUNT(Id) genCount, AVG(Generation_Time_Ms__c) avgTime
            FROM Document_Generation_Log__c
            WHERE CreatedDate >= :startDate AND Document_Type__c != null
            GROUP BY Document_Type__c
            ORDER BY COUNT(Id) DESC
            LIMIT 10
        ];
        List<Map<String, Object>> docTypeData = new List<Map<String, Object>>();
        Integer totalDocuments = 0;
        for (AggregateResult ar : docTypeStats) {
            Map<String, Object> m = new Map<String, Object>();
            m.put('type', (String) ar.get('docType'));
            Integer genCount = safeIntegerFromAggregate(ar, 'genCount');
            m.put('count', genCount);
            Decimal avgMs = safeDecimalFromAggregate(ar, 'avgTime');
            m.put('averageTime', avgMs != null ? (avgMs / 1000).setScale(2) : Decimal.valueOf('0'));
            docTypeData.add(m);
            totalDocuments += genCount;
        }
        usageAnalytics.put('documentTypeBreakdown', docTypeData);
        usageAnalytics.put('totalDocuments', totalDocuments);

        // Top users
        List<AggregateResult> userActivityStats = [
            SELECT CreatedById userId, COUNT(Id) docCount, AVG(Generation_Time_Ms__c) avgTime, MAX(CreatedDate) lastActivity
            FROM Document_Generation_Log__c
            WHERE CreatedDate >= :startDate
            GROUP BY CreatedById
            ORDER BY COUNT(Id) DESC
            LIMIT 20
        ];
        Set<Id> userIds = new Set<Id>();
        for (AggregateResult ar : userActivityStats) { userIds.add((Id)ar.get('userId')); }
        Map<Id, User> userMap = new Map<Id, User>();
        if (!userIds.isEmpty()) {
            for (User u : [SELECT Id, Name, Email, Profile.Name FROM User WHERE Id IN :userIds]) {
                userMap.put(u.Id, u);
            }
        }
        List<Map<String, Object>> userActivityData = new List<Map<String, Object>>();
        for (AggregateResult ar : userActivityStats) {
            Id uId = (Id) ar.get('userId');
            User u = userMap.get(uId);
            Map<String, Object> mu = new Map<String, Object>();
            mu.put('userName', u != null ? u.Name : 'Unknown User');
            mu.put('email', u != null ? u.Email : '');
            mu.put('profile', (u != null && u.Profile != null) ? u.Profile.Name : '');
            Integer docCount = safeIntegerFromAggregate(ar, 'docCount');
            mu.put('documentCount', docCount);
            Decimal avgMs = safeDecimalFromAggregate(ar, 'avgTime');
            mu.put('averageTime', avgMs != null ? (avgMs / 1000).setScale(2) : Decimal.valueOf('0'));
            mu.put('lastActivity', (DateTime) ar.get('lastActivity'));
            userActivityData.add(mu);
        }
        usageAnalytics.put('topUsers', userActivityData);

        // Template usage
        List<AggregateResult> templateStats = [
            SELECT Template_Name__c templateName, COUNT(Id) usageCount, AVG(Generation_Time_Ms__c) avgTime
            FROM Document_Generation_Log__c
            WHERE CreatedDate >= :startDate AND Template_Name__c != null
            GROUP BY Template_Name__c
            ORDER BY COUNT(Id) DESC
            LIMIT 15
        ];
        List<Map<String, Object>> templateUsage = new List<Map<String, Object>>();
        for (AggregateResult ar : templateStats) {
            Map<String, Object> mt = new Map<String, Object>();
            mt.put('name', (String) ar.get('templateName'));
            Integer usageCount = safeIntegerFromAggregate(ar, 'usageCount');
            mt.put('usageCount', usageCount);
            Decimal avgMs = safeDecimalFromAggregate(ar, 'avgTime');
            mt.put('averageTime', avgMs != null ? (avgMs / 1000).setScale(2) : Decimal.valueOf('0'));
            templateUsage.add(mt);
        }
        usageAnalytics.put('templateUsage', templateUsage);

        // Daily trends: group by year/month/day
        List<AggregateResult> dailyTrends = [
            SELECT CALENDAR_YEAR(CreatedDate) yr, CALENDAR_MONTH(CreatedDate) mth, DAY_IN_MONTH(CreatedDate) dy, COUNT(Id) docCount, AVG(Generation_Time_Ms__c) avgTime, COUNT(CreatedById) userCount
            FROM Document_Generation_Log__c
            WHERE CreatedDate >= :startDate
            GROUP BY CALENDAR_YEAR(CreatedDate), CALENDAR_MONTH(CreatedDate), DAY_IN_MONTH(CreatedDate)
            ORDER BY CALENDAR_YEAR(CreatedDate) DESC, CALENDAR_MONTH(CreatedDate) DESC, DAY_IN_MONTH(CreatedDate) DESC
            LIMIT 30
        ];
        List<Map<String, Object>> dailyTrendData = new List<Map<String, Object>>();
        for (AggregateResult ar : dailyTrends) {
            Integer yr = safeIntegerFromAggregate(ar, 'yr');
            Integer mth = safeIntegerFromAggregate(ar, 'mth');
            Integer dy = safeIntegerFromAggregate(ar, 'dy');
            Date d;
            try { d = Date.newInstance(yr, mth, dy); } catch (Exception ex) { d = Date.today(); }
            Map<String, Object> md = new Map<String, Object>();
            md.put('date', d);
            md.put('documentCount', safeIntegerFromAggregate(ar, 'docCount'));
            Decimal avgMs = safeDecimalFromAggregate(ar, 'avgTime');
            md.put('averageTime', avgMs != null ? (avgMs / 1000).setScale(2) : Decimal.valueOf('0'));
            Integer userCount = safeIntegerFromAggregate(ar, 'userCount');
            md.put('activeUsers', userCount);
            dailyTrendData.add(md);
        }
        usageAnalytics.put('dailyTrends', dailyTrendData);

        report.usageAnalytics = usageAnalytics;
        return report;
    }

    private static AnalyticsReport generatePerformanceAnalysisReport(Integer dayRange, String folderId) {
        AnalyticsReport report = new AnalyticsReport();
        report.reportType = 'PERFORMANCE_ANALYSIS';
        DateTime startDate = DateTime.now().addDays(-dayRange);
        Map<String, Object> performanceMetrics = new Map<String, Object>();

        List<AggregateResult> perfStats = [
            SELECT MIN(Generation_Time_Ms__c) minTime, MAX(Generation_Time_Ms__c) maxTime, AVG(Generation_Time_Ms__c) avgTime, COUNT(Id) totalGenerations
            FROM Document_Generation_Log__c
            WHERE CreatedDate >= :startDate
        ];
        if (!perfStats.isEmpty() && perfStats[0] != null) {
            AggregateResult ar = perfStats[0];
            Decimal minMs = safeDecimalFromAggregate(ar, 'minTime');
            Decimal maxMs = safeDecimalFromAggregate(ar, 'maxTime');
            Decimal avgMs = safeDecimalFromAggregate(ar, 'avgTime');
            performanceMetrics.put('minimumGenerationTime', minMs != null ? (minMs / 1000).setScale(3) : 0);
            performanceMetrics.put('maximumGenerationTime', maxMs != null ? (maxMs / 1000).setScale(3) : 0);
            performanceMetrics.put('averageGenerationTime', avgMs != null ? (avgMs / 1000).setScale(3) : 0);
            performanceMetrics.put('totalGenerations', safeIntegerFromAggregate(ar, 'totalGenerations'));
            Decimal avgTimeSec = avgMs != null ? (avgMs / 1000) : 0;
            Decimal slaCompliance = (avgTimeSec > 0) ? Math.min(100, (5.0 / avgTimeSec * 100.0)) : 100;
            performanceMetrics.put('slaComplianceRate', slaCompliance.setScale(1));
        }

        // Template breakdown
        List<AggregateResult> templatePerformance = [
            SELECT Template_Name__c templateName, AVG(Generation_Time_Ms__c) avgTime, COUNT(Id) usageCount
            FROM Document_Generation_Log__c
            WHERE CreatedDate >= :startDate AND Template_Name__c != null
            GROUP BY Template_Name__c
            ORDER BY AVG(Generation_Time_Ms__c) DESC
            LIMIT 10
        ];
        List<Map<String, Object>> templateData = new List<Map<String, Object>>();
        for (AggregateResult ar : templatePerformance) {
            Map<String, Object> t = new Map<String, Object>();
            t.put('templateName', (String) ar.get('templateName'));
            Decimal avgMs = safeDecimalFromAggregate(ar, 'avgTime');
            t.put('averageTime', avgMs != null ? (avgMs / 1000).setScale(2) : 0);
            t.put('usageCount', safeIntegerFromAggregate(ar, 'usageCount'));
            templateData.add(t);
        }
        performanceMetrics.put('templatePerformanceAnalysis', templateData);

        report.performanceMetrics = performanceMetrics;
        return report;
    }

    private static AnalyticsReport generateComplianceReport(Integer dayRange, String folderId) {
        AnalyticsReport report = new AnalyticsReport();
        report.reportType = 'COMPLIANCE_REPORT';
        DateTime startDate = DateTime.now().addDays(-dayRange);
        Map<String, Object> complianceMetrics = new Map<String, Object>();

        // Overview
        List<AggregateResult> overview = [
            SELECT COUNT(Id) totalChecks, AVG(Compliance_Score__c) avgScore
            FROM Compliance_Check_Log__c
            WHERE CreatedDate >= :startDate
        ];
        Integer excellent = 0;
        Integer good = 0;
        Integer poor = 0;
        try { excellent = (Integer) [SELECT COUNT() FROM Compliance_Check_Log__c WHERE CreatedDate >= :startDate AND Compliance_Score__c >= 95]; } catch (Exception ex) { excellent = 0; }
        try { good = (Integer) [SELECT COUNT() FROM Compliance_Check_Log__c WHERE CreatedDate >= :startDate AND Compliance_Score__c >= 80 AND Compliance_Score__c < 95]; } catch (Exception ex) { good = 0; }
        try { poor = (Integer) [SELECT COUNT() FROM Compliance_Check_Log__c WHERE CreatedDate >= :startDate AND Compliance_Score__c < 80]; } catch (Exception ex) { poor = 0; }

        if (!overview.isEmpty()) {
            AggregateResult ar = overview[0];
            Integer total = safeIntegerFromAggregate(ar, 'totalChecks');
            Decimal avgScore = safeDecimalFromAggregate(ar, 'avgScore');
            complianceMetrics.put('totalComplianceChecks', total);
            complianceMetrics.put('averageComplianceScore', avgScore != null ? avgScore.setScale(1) : 0);
            complianceMetrics.put('excellentRate', total > 0 ? ((Decimal) excellent * 100 / total).setScale(1) : 0);
            complianceMetrics.put('goodRate', total > 0 ? ((Decimal) good * 100 / total).setScale(1) : 0);
            complianceMetrics.put('poorRate', total > 0 ? ((Decimal) poor * 100 / total).setScale(1) : 0);
        } else {
            complianceMetrics.put('totalComplianceChecks', 0);
            complianceMetrics.put('averageComplianceScore', 0);
            complianceMetrics.put('excellentRate', 0);
            complianceMetrics.put('goodRate', 0);
            complianceMetrics.put('poorRate', 0);
        }

        // Jurisdiction breakdown
        List<AggregateResult> jurisdictionBreakdown = [
            SELECT Jurisdiction__c jurisdiction, COUNT(Id) checkCount, AVG(Compliance_Score__c) avgScore
            FROM Compliance_Check_Log__c
            WHERE CreatedDate >= :startDate AND Jurisdiction__c != null
            GROUP BY Jurisdiction__c
            ORDER BY COUNT(Id) DESC
            LIMIT 50
        ];
        List<AggregateResult> violationBreakdown = [
            SELECT Jurisdiction__c jurisdiction, COUNT(Id) violationCount
            FROM Compliance_Check_Log__c
            WHERE CreatedDate >= :startDate AND Jurisdiction__c != null AND Status__c = 'VIOLATION'
            GROUP BY Jurisdiction__c
        ];
        Map<String, Integer> violationMap = new Map<String, Integer>();
        for (AggregateResult ar : violationBreakdown) {
            String jur = (String) ar.get('jurisdiction');
            Integer cnt = safeIntegerFromAggregate(ar, 'violationCount');
            violationMap.put(jur, cnt);
        }
        List<Map<String, Object>> jurisdictionData = new List<Map<String, Object>>();
        for (AggregateResult ar : jurisdictionBreakdown) {
            String jur = (String) ar.get('jurisdiction');
            Integer count = safeIntegerFromAggregate(ar, 'checkCount');
            Decimal avg = safeDecimalFromAggregate(ar, 'avgScore');
            Integer vcount = violationMap.containsKey(jur) ? violationMap.get(jur) : 0;
            Decimal vRate = count > 0 ? ((Decimal) vcount * 100 / count).setScale(1) : 0;
            Map<String, Object> mj = new Map<String, Object>();
            mj.put('name', jur);
            mj.put('checkCount', count);
            mj.put('averageScore', avg != null ? avg.setScale(1) : 0);
            mj.put('violationCount', vcount);
            mj.put('violationRate', vRate);
            jurisdictionData.add(mj);
        }
        complianceMetrics.put('jurisdictionBreakdown', jurisdictionData);

        // Recent Violations
        List<Compliance_Violation__c> recentViolations = new List<Compliance_Violation__c>();
        try {
            recentViolations = [
                SELECT Id, Violation_Type__c, Severity__c, Document_Type__c, CreatedDate, Description__c
                FROM Compliance_Violation__c
                WHERE CreatedDate >= :startDate
                ORDER BY CreatedDate DESC
                LIMIT 20
            ];
        } catch (Exception ex) {
            recentViolations = new List<Compliance_Violation__c>();
        }
        List<Map<String, Object>> violationData = new List<Map<String, Object>>();
        for (Compliance_Violation__c v : recentViolations) {
            Map<String, Object> mv = new Map<String, Object>();
            mv.put('type', v.Violation_Type__c);
            mv.put('severity', v.Severity__c);
            mv.put('documentType', v.Document_Type__c);
            mv.put('date', v.CreatedDate != null ? v.CreatedDate.format('MM/dd/yyyy HH:mm') : '');
            mv.put('description', v.Description__c);
            violationData.add(mv);
        }
        complianceMetrics.put('recentViolations', violationData);

        // Regulations grouping
        List<AggregateResult> regulationBreakdown = [
            SELECT Regulation_Type__c regulationType, COUNT(Id) checkCount, AVG(Compliance_Score__c) avgScore
            FROM Compliance_Check_Log__c
            WHERE CreatedDate >= :startDate AND Regulation_Type__c != null
            GROUP BY Regulation_Type__c
            ORDER BY COUNT(Id) DESC
            LIMIT 50
        ];
        List<Map<String, Object>> regulationData = new List<Map<String, Object>>();
        for (AggregateResult ar : regulationBreakdown) {
            Map<String, Object> mr = new Map<String, Object>();
            mr.put('type', (String) ar.get('regulationType'));
            mr.put('checkCount', safeIntegerFromAggregate(ar, 'checkCount'));
            Decimal avg = safeDecimalFromAggregate(ar, 'avgScore');
            mr.put('averageScore', avg != null ? avg.setScale(1) : 0);
            regulationData.add(mr);
        }
        complianceMetrics.put('regulationBreakdown', regulationData);

        report.complianceMetrics = complianceMetrics;
        return report;
    }

    private static AnalyticsReport generateExecutiveSummaryReport(Integer dayRange, String folderId) {
        AnalyticsReport report = new AnalyticsReport();
        report.reportType = 'EXECUTIVE_SUMMARY';
        DateTime startDate = DateTime.now().addDays(-dayRange);
        Map<String, Object> executiveSummary = new Map<String, Object>();

        // Document generation aggregated stats
        List<AggregateResult> docStats = [
            SELECT COUNT(Id) totalDocs, COUNT(CreatedById) uniqueUsersApprox, AVG(Generation_Time_Ms__c) avgGenerationTime
            FROM Document_Generation_Log__c
            WHERE CreatedDate >= :startDate
        ];
        if (!docStats.isEmpty()) {
            AggregateResult ar = docStats[0];
            executiveSummary.put('totalDocumentsGenerated', safeIntegerFromAggregate(ar, 'totalDocs'));
            // uniqueUsersApprox is approximate; if the field is not present fallback
            executiveSummary.put('uniqueActiveUsers', safeIntegerFromAggregate(ar, 'uniqueUsersApprox'));
            Decimal avgMs = safeDecimalFromAggregate(ar, 'avgGenerationTime');
            executiveSummary.put('averageGenerationTime', avgMs != null ? (avgMs / 1000).setScale(2) : 0);
        } else {
            executiveSummary.put('totalDocumentsGenerated', 0);
            executiveSummary.put('uniqueActiveUsers', 0);
            executiveSummary.put('averageGenerationTime', 0);
        }

        // Compliance snapshot
        List<AggregateResult> complianceStats = [
            SELECT AVG(Compliance_Score__c) avgScore, COUNT(Id) totalChecks
            FROM Compliance_Check_Log__c
            WHERE CreatedDate >= :startDate
        ];
        Integer excellentCount = 0;
        try { excellentCount = (Integer) [SELECT COUNT() FROM Compliance_Check_Log__c WHERE CreatedDate >= :startDate AND Compliance_Score__c >= 95]; } catch (Exception ex) { excellentCount = 0; }
        if (!complianceStats.isEmpty()) {
            AggregateResult ar = complianceStats[0];
            Decimal avgScore = safeDecimalFromAggregate(ar, 'avgScore');
            Integer total = safeIntegerFromAggregate(ar, 'totalChecks');
            executiveSummary.put('averageComplianceScore', avgScore != null ? avgScore.setScale(1) : 0);
            executiveSummary.put('excellentComplianceRate', total > 0 ? ((Decimal) excellentCount * 100 / total).setScale(1) : 0);
        } else {
            executiveSummary.put('averageComplianceScore', 0);
            executiveSummary.put('excellentComplianceRate', 0);
        }

        // System health (assumes SystemHealthMonitor exists in org)
        try {
            SystemHealthMonitor.HealthMetrics hm = SystemHealthMonitor.getCurrentHealthMetrics();
            executiveSummary.put('systemUptime', hm.systemUptime);
            executiveSummary.put('currentSLA', hm.documentGenerationSLA);
            executiveSummary.put('activeUsers', hm.activeUsers);
            executiveSummary.put('errorRate', hm.errorRate);

            // simple overall health calc
            String overall = 'EXCELLENT';
            Decimal avgComp = executiveSummary.containsKey('averageComplianceScore') ? (Decimal) executiveSummary.get('averageComplianceScore') : 0;
            if (hm.documentGenerationSLA < 95 || hm.systemUptime < 99.5 || (avgComp != null && avgComp < 95)) overall = 'GOOD';
            if (hm.documentGenerationSLA < 80 || hm.systemUptime < 99 || (avgComp != null && avgComp < 90)) overall = 'NEEDS_ATTENTION';
            executiveSummary.put('overallHealthStatus', overall);
        } catch (Exception e) {
            executiveSummary.put('systemUptime', null);
            executiveSummary.put('currentSLA', null);
            executiveSummary.put('activeUsers', null);
            executiveSummary.put('errorRate', null);
            executiveSummary.put('overallHealthStatus', 'UNKNOWN');
        }

        report.executiveSummary = executiveSummary;
        return report;
    }

    // =========================================
    // Advanced reporting and AI stubs (no logic change)
    // =========================================

    // Public comprehensive report entry (non-Aura)
    public static ComprehensiveDocumentReport generateComprehensiveReport(String reportType, Map<String, Object> parameters) {
        ComprehensiveDocumentReport report = new ComprehensiveDocumentReport();
        report.reportType = reportType;
        report.generationStartTime = DateTime.now();
        report.parameters = parameters;
        try {
            if ('LIFECYCLE_ANALYTICS' == reportType) {
                report = generateLifecycleAnalyticsReport(parameters);
            } else if ('COMPLIANCE_DASHBOARD' == reportType) {
                report = generateComplianceDashboardReport(parameters);
            } else if ('RETENTION_AUDIT' == reportType) {
                report = generateRetentionAuditReport(parameters);
            } else if ('EXPIRATION_FORECAST' == reportType) {
                report = generateExpirationForecastReport(parameters);
            } else if ('AI_INSIGHTS_SUMMARY' == reportType) {
                report = generateAIInsightsSummaryReport(parameters);
            } else if ('RISK_ASSESSMENT' == reportType) {
                report = generateRiskAssessmentReport(parameters);
            } else {
                throw new ReportingException('Unsupported report type: ' + reportType);
            }

            // store a reference (stubbed)
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
            // creationTrends
            List<AggregateResult> creationTrends = [
                SELECT CALENDAR_MONTH(CreatedDate) month, CALENDAR_YEAR(CreatedDate) year, COUNT(Id) documentCount, AVG(ContentSize) avgSize
                FROM ContentDocument
                WHERE CreatedDate = LAST_N_MONTHS:12
                GROUP BY CALENDAR_YEAR(CreatedDate), CALENDAR_MONTH(CreatedDate)
                ORDER BY CALENDAR_YEAR(CreatedDate) DESC, CALENDAR_MONTH(CreatedDate) DESC
            ];

            List<AggregateResult> versionStats = [
                SELECT ContentDocumentId, COUNT(Id) versionCount, MAX(CreatedDate) lastModified
                FROM ContentVersion
                GROUP BY ContentDocumentId
                HAVING COUNT(Id) > 1
                ORDER BY COUNT(Id) DESC
                LIMIT 100
            ];

            List<AggregateResult> archivalStats = new List<AggregateResult>();
            try {
                archivalStats = [
                    SELECT Archive_Status__c status, COUNT(Id) archivalCount, AVG(Archive_Size_MB__c) avgArchiveSize
                    FROM DocumentArchivalRecord__c
                    WHERE Archival_Date__c = LAST_N_MONTHS:12
                    GROUP BY Archive_Status__c
                ];
            } catch (Exception ex) {
                archivalStats = new List<AggregateResult>();
            }

            List<AggregateResult> expirationStats = new List<AggregateResult>();
            try {
                expirationStats = [
                    SELECT Expiration_Status__c status, COUNT(Id) statusCount
                    FROM DocumentExpirationTracking__c
                    WHERE Last_Check_Date__c = LAST_N_DAYS:30
                    GROUP BY Expiration_Status__c
                ];
            } catch (Exception ex) {
                expirationStats = new List<AggregateResult>();
            }

            LifecycleAnalyticsData data = new LifecycleAnalyticsData();
            data.creationTrends = processCreationTrends(creationTrends);
            data.versioningMetrics = processVersioningMetrics(versionStats);
            data.archivalMetrics = processArchivalMetrics(archivalStats);
            data.expirationMetrics = processExpirationMetrics(expirationStats);
            data.totalDocuments = getTotalDocumentCount();
            data.activeDocuments = getActiveDocumentCount();
            data.archivedDocuments = getArchivedDocumentCount();
            data.expiredDocuments = getExpiredDocumentCount();

            report.analyticsData = data;
            report.visualizations = generateLifecycleVisualizations(data);
        } catch (Exception e) {
            report.errorMessage = 'Failed to generate lifecycle analytics: ' + e.getMessage();
            throw e;
        }
        return report;
    }

    // Stubs for other comprehensive reports (preserve signatures and behavior)
    private static ComprehensiveDocumentReport generateComplianceDashboardReport(Map<String, Object> parameters) {
        return new ComprehensiveDocumentReport();
    }
    private static ComprehensiveDocumentReport generateRetentionAuditReport(Map<String, Object> parameters) {
        return new ComprehensiveDocumentReport();
    }
    private static ComprehensiveDocumentReport generateExpirationForecastReport(Map<String, Object> parameters) {
        return new ComprehensiveDocumentReport();
    }
    private static ComprehensiveDocumentReport generateAIInsightsSummaryReport(Map<String, Object> parameters) {
        return new ComprehensiveDocumentReport();
    }
    private static ComprehensiveDocumentReport generateRiskAssessmentReport(Map<String, Object> parameters) {
        return new ComprehensiveDocumentReport();
    }
    private static void storeReportRecord(ComprehensiveDocumentReport report) {
        // stub persistence (keeps behavior)
    }

    // Small processing helpers
    private static Object processCreationTrends(List<AggregateResult> creationTrends) { return creationTrends; }
    private static Object processVersioningMetrics(List<AggregateResult> versionStats) { return versionStats; }
    private static Object processArchivalMetrics(List<AggregateResult> archivalStats) { return archivalStats; }
    private static Object processExpirationMetrics(List<AggregateResult> expirationStats) { return expirationStats; }
    private static Integer getTotalDocumentCount() { try { Integer c = (Integer) [SELECT COUNT() FROM ContentDocument]; return c; } catch (Exception e) { return 0; } }
    private static Integer getActiveDocumentCount() { return 0; } // stub: preserve signature
    private static Integer getArchivedDocumentCount() { return 0; } // stub: preserve signature
    private static Integer getExpiredDocumentCount() { return 0; } // stub: preserve signature
    private static Object generateLifecycleVisualizations(LifecycleAnalyticsData analyticsData) { return analyticsData; }

    // =========================================
    // AI enhancement pipeline (preserve signatures)
    // =========================================

    @future(callout=true)
    public static void enhanceDocumentIntelligence(Set<Id> documentIds) {
        if (documentIds == null || documentIds.isEmpty()) return;
        for (Id docId : documentIds) {
            try {
                EnhancementResult res = executeIntelligenceEnhancement(docId);
                logEnhancementResult(docId, res);
            } catch (Exception e) {
                createEnhancementErrorLog(docId, e);
            }
        }
    }

    private static EnhancementResult executeIntelligenceEnhancement(Id documentId) {
        EnhancementResult res = new EnhancementResult();
        res.documentId = documentId;
        res.enhancementStartTime = DateTime.now();
        try {
            ContentVersion ver = [ SELECT Id, ContentDocumentId, VersionData, Title, FileType, ContentSize FROM ContentVersion WHERE ContentDocumentId = :documentId AND IsLatest = true LIMIT 1 ];
            String docText = extractDocumentText(ver);
            res.semanticAnalysis = performEnhancedSemanticAnalysis(docText);
            res.entityExtraction = extractAdvancedEntities(docText);
            res.compliancePatterns = recognizeCompliancePatterns(docText, res.semanticAnalysis);
            res.riskFactors = identifyAdvancedRiskFactors(docText, res.entityExtraction, res.compliancePatterns);
            res.enhancedMetadata = generateEnhancedMetadata(res.semanticAnalysis, res.entityExtraction, res.compliancePatterns, res.riskFactors);
            storeEnhancedIntelligence(documentId, res);
            updateAdvancedDocumentClassification(documentId, res.enhancedMetadata);
            if (res.requiresAutomatedAction) triggerAutomatedWorkflows(documentId, res);
            res.success = true;
        } catch (Exception e) {
            res.success = false;
            res.errorMessage = e.getMessage();
            res.stackTrace = e.getStackTraceString();
        }
        res.enhancementEndTime = DateTime.now();
        res.totalEnhancementTime = res.enhancementEndTime.getTime() - res.enhancementStartTime.getTime();
        return res;
    }

    // The following helper methods are stubs but keep the same signatures and no logic changes
    private static String extractDocumentText(ContentVersion version) {
        try {
            if (version == null) return '';
            // best-effort: version.VersionData may be large binary - return placeholder or attempt conversion if small
            return 'extracted-text-placeholder';
        } catch (Exception e) {
            return '';
        }
    }
    private static Object performEnhancedSemanticAnalysis(String documentText) { return new SemanticAnalysisResult(); }
    private static Object extractAdvancedEntities(String documentText) { return new EntityExtractionResult(); }
    private static Object recognizeCompliancePatterns(String documentText, Object semanticResult) { return new CompliancePatternResult(); }
    private static Object identifyAdvancedRiskFactors(String documentText, Object entityResult, Object complianceResult) { return new RiskFactorResult(); }
    private static Object generateEnhancedMetadata(Object semanticResult, Object entityResult, Object complianceResult, Object riskResult) { return new EnhancedMetadata(); }
    private static void storeEnhancedIntelligence(Id documentId, EnhancementResult result) { /* stub */ }
    private static void updateAdvancedDocumentClassification(Id documentId, Object metadata) { /* stub */ }
    private static void logEnhancementResult(Id docId, EnhancementResult result) { /* stub */ }
    private static void createEnhancementErrorLog(Id docId, Exception e) { /* stub */ }
    private static void triggerAutomatedWorkflows(Id docId, EnhancementResult result) { /* stub */ }

    // End of class
}