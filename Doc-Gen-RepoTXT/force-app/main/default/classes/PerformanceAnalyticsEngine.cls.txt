public class PerformanceAnalyticsEngine {

    // Performance thresholds
    public static final Decimal RESPONSE_TIME_THRESHOLD = 5.0; // seconds
    public static final Decimal UPTIME_TARGET = 99.5; // percentage
    public static final Decimal CACHE_HIT_TARGET = 85.0; // percentage
    public static final Integer MAX_CONCURRENT_USERS = 500;

    /**
     * Get comprehensive performance dashboard data
     */
    @AuraEnabled(cacheable=true)
    public static PerformanceDashboard getPerformanceDashboard() {
        try {
            // System performance metrics
            SystemMetrics systemMetrics = calculateSystemMetrics();
            
            // Document processing analytics
            DocumentAnalytics documentAnalytics = calculateDocumentAnalytics();
            
            // User activity insights
            UserActivityMetrics userMetrics = calculateUserActivityMetrics();
            
            // Compliance monitoring
            ComplianceMetrics complianceMetrics = calculateComplianceMetrics();
            
            // Generate performance recommendations
            List<PerformanceRecommendation> recommendations = generatePerformanceRecommendations(
                systemMetrics,
                documentAnalytics,
                userMetrics,
                complianceMetrics
            );

            
            return new PerformanceDashboard(
                systemMetrics,
                documentAnalytics, 
                userMetrics,
                complianceMetrics,
                recommendations
            );
            
        } catch (Exception e) {
            throw new AuraHandledException(
                'Performance analytics failed: ' + e.getMessage()
            );
        }
    }
    
    // /**
    //  * Calculate real-time system performance metrics
    //  */
    // private static SystemMetrics calculateSystemMetrics() {
    //     List<AggregateResult> performanceData = [
    //         SELECT 
    //             AVG(ResponseTime__c) avgResponseTime,
    //             MAX(ResponseTime__c) maxResponseTime,
    //             COUNT(Id) totalRequests,
    //             SUM(CASE WHEN ResponseTime__c <= 5 THEN 1 ELSE 0 END) fastResponses
    //         FROM SystemPerformanceLog__c 
    //         WHERE CreatedDate = LAST_N_HOURS:24
    //     ];

    //     Decimal avgResponseTime = 0;
    //     Decimal maxResponseTime = 0;
    //     Integer totalRequests = 0;
    //     Decimal responseTimeCompliance = 100;

    //     if (!performanceData.isEmpty()) {
    //         AggregateResult data = performanceData[0];

    //         avgResponseTime = data.get('avgResponseTime') != null ? (Decimal)data.get('avgResponseTime') : 0;
    //         maxResponseTime = data.get('maxResponseTime') != null ? (Decimal)data.get('maxResponseTime') : 0;
    //         totalRequests = data.get('totalRequests') != null ? (Integer)data.get('totalRequests') : 0;
    //         Integer fastResponses = data.get('fastResponses') != null ? (Integer)data.get('fastResponses') : 0;

    //         if (totalRequests > 0) {
    //             responseTimeCompliance = (Decimal.valueOf(fastResponses) / totalRequests) * 100;
    //         }
    //     }

    //     Decimal uptimePercentage = calculateUptimePercentage();
    //     Integer currentConcurrentUsers = getCurrentConcurrentUsers();
    //     Integer maxConcurrentUsers = getMaxConcurrentUsers();

    //     Decimal systemHealthScore = calculateSystemHealthScore(
    //         avgResponseTime,
    //         uptimePercentage,
    //         responseTimeCompliance,
    //         currentConcurrentUsers
    //     );

    //     return new SystemMetrics(
    //         avgResponseTime,
    //         maxResponseTime,
    //         responseTimeCompliance,
    //         uptimePercentage,
    //         currentConcurrentUsers,
    //         maxConcurrentUsers,
    //         systemHealthScore,
    //         totalRequests
    //     );
    // }

    /**
 * Calculate real-time system performance metrics
 */
private static SystemMetrics calculateSystemMetrics() {
    // 24-hour window
    DateTime since = System.now().addHours(-24);

    // Aggregate metrics (avg, max, count)
    List<AggregateResult> performanceData = [
        SELECT
            AVG(ResponseTime__c) avgResponseTime,
            MAX(ResponseTime__c) maxResponseTime,
            COUNT(Id) totalRequests
        FROM SystemPerformanceLog__c
        WHERE CreatedDate >= :since
    ];

    // Count of "fast" responses (<= 5)
    Integer fastResponses = [
        SELECT COUNT()
        FROM SystemPerformanceLog__c
        WHERE CreatedDate >= :since
        AND ResponseTime__c <= 5
    ];

    // Defaults
    Decimal avgResponseTime = 0;
    Decimal maxResponseTime = 0;
    Integer totalRequests = 0;
    Decimal responseTimeCompliance = 100;

    if (!performanceData.isEmpty()) {
        AggregateResult ar = performanceData[0];

        // Use safe conversion via String to avoid casting issues
        if (ar.get('avgResponseTime') != null) {
            avgResponseTime = Decimal.valueOf(String.valueOf(ar.get('avgResponseTime')));
        }
        if (ar.get('maxResponseTime') != null) {
            maxResponseTime = Decimal.valueOf(String.valueOf(ar.get('maxResponseTime')));
        }
        if (ar.get('totalRequests') != null) {
            totalRequests = Integer.valueOf(String.valueOf(ar.get('totalRequests')));
        }

        if (totalRequests > 0) {
            responseTimeCompliance = (Decimal.valueOf(fastResponses) / Decimal.valueOf(totalRequests)) * 100;
        }
    }

    // Other metrics (your existing helper methods)
    Decimal uptimePercentage = calculateUptimePercentage();
    Integer currentConcurrentUsers = getCurrentConcurrentUsers();
    Integer maxConcurrentUsers = getMaxConcurrentUsers();

    Decimal systemHealthScore = calculateSystemHealthScore(
        avgResponseTime,
        uptimePercentage,
        responseTimeCompliance,
        currentConcurrentUsers
    );

    return new SystemMetrics(
        avgResponseTime,
        maxResponseTime,
        responseTimeCompliance,
        uptimePercentage,
        currentConcurrentUsers,
        maxConcurrentUsers,
        systemHealthScore,
        totalRequests
    );
}

    // /**
    //  * Calculate document processing analytics
    //  */
    // private static DocumentAnalytics calculateDocumentAnalytics() {
    //     // Document generation performance
    //     List<AggregateResult> generationStats = [
    //         SELECT 
    //             COUNT(Id) totalGenerated,
    //             AVG(GenerationTime__c) avgGenerationTime,
    //             SUM(CASE WHEN ProcessingStatus__c = 'Completed' THEN 1 ELSE 0 END) completedDocs,
    //             SUM(CASE WHEN ProcessingStatus__c = 'Failed' THEN 1 ELSE 0 END) failedDocs
    //         FROM DocumentLifecycleConfiguration__c 
    //         WHERE CreatedDate = LAST_N_DAYS:30
    //     ];
        
    //     Integer totalGenerated = 0;
    //     Decimal avgGenerationTime = 0;
    //     Integer completedDocs = 0;
    //     Integer failedDocs = 0;
    //     Decimal successRate = 100;
        
    //     if (!generationStats.isEmpty()) {
    //         AggregateResult stats = generationStats[0];
    //         totalGenerated = (Integer)stats.get('totalGenerated') != null ? (Integer)stats.get('totalGenerated') : 0;
    //         avgGenerationTime = (Decimal)stats.get('avgGenerationTime') != null ? (Decimal)stats.get('avgGenerationTime') : 0;
    //         completedDocs = (Integer)stats.get('completedDocs') != null ? (Integer)stats.get('completedDocs') : 0;
    //         failedDocs = (Integer)stats.get('failedDocs') != null ? (Integer)stats.get('failedDocs') : 0;

    //         if (totalGenerated > 0) {
    //             successRate = (Decimal.valueOf(completedDocs) / totalGenerated) * 100;
    //         }
    //     }

    //     // Signature completion analytics
    //     List<AggregateResult> signatureStats = [
    //         SELECT 
    //             COUNT(Id) totalSignatureRequests,
    //             AVG(CompletionTime__c) avgCompletionTime,
    //             SUM(CASE WHEN Status__c = 'Signed' THEN 1 ELSE 0 END) completedSignatures,
    //             SUM(CASE WHEN Status__c = 'Rejected' THEN 1 ELSE 0 END) rejectedSignatures,
    //             SUM(CASE WHEN Status__c = 'Expired' THEN 1 ELSE 0 END) expiredSignatures
    //         FROM Signature_Request__c 
    //         WHERE CreatedDate = LAST_N_DAYS:30
    //     ];

    //     Integer totalSignatureRequests = 0;
    //     Decimal avgCompletionTime = 0;
    //     Integer completedSignatures = 0;
    //     Integer rejectedSignatures = 0;
    //     Integer expiredSignatures = 0;
    //     Decimal signatureSuccessRate = 100;

    //     if (!signatureStats.isEmpty()) {
    //         AggregateResult sigStats = signatureStats[0];
    //         totalSignatureRequests = (Integer)sigStats.get('totalSignatureRequests') != null ? (Integer)sigStats.get('totalSignatureRequests') : 0;
    //         avgCompletionTime = (Decimal)sigStats.get('avgCompletionTime') != null ? (Decimal)sigStats.get('avgCompletionTime') : 0;
    //         completedSignatures = (Integer)sigStats.get('completedSignatures') != null ? (Integer)sigStats.get('completedSignatures') : 0;
    //         rejectedSignatures = (Integer)sigStats.get('rejectedSignatures') != null ? (Integer)sigStats.get('rejectedSignatures') : 0;
    //         expiredSignatures = (Integer)sigStats.get('expiredSignatures') != null ? (Integer)sigStats.get('expiredSignatures') : 0;
            
    //         if (totalSignatureRequests > 0) {
    //             signatureSuccessRate = (Decimal.valueOf(completedSignatures) / totalSignatureRequests) * 100;
    //         }
    //     }

    //     // Document type performance breakdown
    //     Map<String, DocumentTypeMetrics> documentTypePerformance = calculateDocumentTypePerformance();

    //     // Processing queue metrics
    //     QueueMetrics queueMetrics = calculateQueueMetrics();

    //     // Volume trends over time
    //     List<VolumeDataPoint> volumeTrends = calculateVolumeTrends();

    //     return new DocumentAnalytics(
    //         totalGenerated,
    //         avgGenerationTime,
    //         successRate,
    //         totalSignatureRequests,
    //         avgCompletionTime,
    //         signatureSuccessRate,
    //         completedDocs,
    //         failedDocs,
    //         rejectedSignatures,
    //         expiredSignatures,
    //         documentTypePerformance,
    //         queueMetrics,
    //         volumeTrends
    //     );
    // }
/**
 * Calculate document processing analytics
 */
private static DocumentAnalytics calculateDocumentAnalytics() {
    DateTime since = System.now().addDays(-30);

    // Document generation performance
    List<AggregateResult> generationStats = [
        SELECT 
            COUNT(Id) totalGenerated,
            AVG(GenerationTime__c) avgGenerationTime
        FROM DocumentLifecycleConfiguration__c 
        WHERE CreatedDate >= :since
    ];

    Integer completedDocs = [
        SELECT COUNT()
        FROM DocumentLifecycleConfiguration__c
        WHERE CreatedDate >= :since AND ProcessingStatus__c = 'Completed'
    ];

    Integer failedDocs = [
        SELECT COUNT()
        FROM DocumentLifecycleConfiguration__c
        WHERE CreatedDate >= :since AND ProcessingStatus__c = 'Failed'
    ];

    Integer totalGenerated = 0;
    Decimal avgGenerationTime = 0;
    Decimal successRate = 100;

    if (!generationStats.isEmpty()) {
        AggregateResult stats = generationStats[0];
        totalGenerated = (Integer)stats.get('totalGenerated') != null ? (Integer)stats.get('totalGenerated') : 0;
        avgGenerationTime = stats.get('avgGenerationTime') != null ? 
                            Decimal.valueOf(String.valueOf(stats.get('avgGenerationTime'))) : 0;

        if (totalGenerated > 0) {
            successRate = (Decimal.valueOf(completedDocs) / totalGenerated) * 100;
        }
    }

    // Signature completion analytics
    List<AggregateResult> signatureStats = [
        SELECT 
            COUNT(Id) totalSignatureRequests,
            AVG(CompletionTime__c) avgCompletionTime
        FROM Signature_Request__c 
        WHERE CreatedDate >= :since
    ];

    Integer completedSignatures = [
        SELECT COUNT() 
        FROM Signature_Request__c 
        WHERE CreatedDate >= :since AND Status__c = 'Signed'
    ];

    Integer rejectedSignatures = [
        SELECT COUNT() 
        FROM Signature_Request__c 
        WHERE CreatedDate >= :since AND Status__c = 'Rejected'
    ];

    Integer expiredSignatures = [
        SELECT COUNT() 
        FROM Signature_Request__c 
        WHERE CreatedDate >= :since AND Status__c = 'Expired'
    ];

    Integer totalSignatureRequests = 0;
    Decimal avgCompletionTime = 0;
    Decimal signatureSuccessRate = 100;

    if (!signatureStats.isEmpty()) {
        AggregateResult sigStats = signatureStats[0];
        totalSignatureRequests = (Integer)sigStats.get('totalSignatureRequests') != null ? (Integer)sigStats.get('totalSignatureRequests') : 0;
        avgCompletionTime = sigStats.get('avgCompletionTime') != null ?
                            Decimal.valueOf(String.valueOf(sigStats.get('avgCompletionTime'))) : 0;

        if (totalSignatureRequests > 0) {
            signatureSuccessRate = (Decimal.valueOf(completedSignatures) / totalSignatureRequests) * 100;
        }
    }

    // Document type performance breakdown
    Map<String, DocumentTypeMetrics> documentTypePerformance = calculateDocumentTypePerformance();

    // Processing queue metrics
    QueueMetrics queueMetrics = calculateQueueMetrics();

    // Volume trends over time
    List<VolumeDataPoint> volumeTrends = calculateVolumeTrends();

    return new DocumentAnalytics(
        totalGenerated,
        avgGenerationTime,
        successRate,
        totalSignatureRequests,
        avgCompletionTime,
        signatureSuccessRate,
        completedDocs,
        failedDocs,
        rejectedSignatures,
        expiredSignatures,
        documentTypePerformance,
        queueMetrics,
        volumeTrends
    );
}

    /**
     * Calculate user activity and engagement metrics
     */
    private static UserActivityMetrics calculateUserActivityMetrics() {
        // Active users in different time periods
        List<AggregateResult> activeUserStats = [
            SELECT 
                COUNT_DISTINCT(UserId__c) totalActiveUsers
            FROM UserActivity__c 
            WHERE CreatedDate = LAST_N_DAYS:30
        ];
        
        List<AggregateResult> dailyActiveUsers = [
            SELECT 
                COUNT_DISTINCT(UserId__c) dailyActive
            FROM UserActivity__c 
            WHERE CreatedDate = TODAY
        ];
        
        List<AggregateResult> weeklyActiveUsers = [
            SELECT 
                COUNT_DISTINCT(UserId__c) weeklyActive
            FROM UserActivity__c 
            WHERE CreatedDate = LAST_N_DAYS:7
        ];
        
        Integer totalActiveUsers = !activeUserStats.isEmpty() ? 
            (Integer)activeUserStats[0].get('totalActiveUsers') : 0;
        Integer dailyActive = !dailyActiveUsers.isEmpty() ? 
            (Integer)dailyActiveUsers[0].get('dailyActive') : 0;
        Integer weeklyActive = !weeklyActiveUsers.isEmpty() ? 
            (Integer)weeklyActiveUsers[0].get('weeklyActive') : 0;
        
        // User engagement metrics
        List<AggregateResult> engagementStats = [
            SELECT 
                AVG(SessionDuration__c) avgSessionDuration,
                AVG(ActionsPerSession__c) avgActionsPerSession,
                COUNT(Id) totalSessions
            FROM UserActivity__c 
            WHERE CreatedDate = LAST_N_DAYS:30
        ];
        
        Decimal avgSessionDuration = 0;
        Decimal avgActionsPerSession = 0;
        Integer totalSessions = 0;
        
        if (!engagementStats.isEmpty()) {
            AggregateResult engagement = engagementStats[0];
            avgSessionDuration = (Decimal)engagement.get('avgSessionDuration') != null ? (Decimal)engagement.get('avgSessionDuration') : 0;
            avgActionsPerSession = (Decimal)engagement.get('avgActionsPerSession') != null ? (Decimal)engagement.get('avgActionsPerSession') : 0;
            totalSessions = (Integer)engagement.get('totalSessions') != null ? (Integer)engagement.get('totalSessions') : 0;
        }
        
        // Feature usage statistics
        Map<String, Integer> featureUsage = calculateFeatureUsage();
        
        // User adoption metrics
        UserAdoptionMetrics adoptionMetrics = calculateUserAdoptionMetrics();
        
        // Calculate user engagement score
        Decimal engagementScore = calculateUserEngagementScore(
            avgSessionDuration,
            avgActionsPerSession,
            dailyActive,
            weeklyActive,
            totalActiveUsers
        );
        
        return new UserActivityMetrics(
            totalActiveUsers,
            dailyActive,
            weeklyActive,
            avgSessionDuration,
            avgActionsPerSession,
            totalSessions,
            engagementScore,
            featureUsage,
            adoptionMetrics
        );
    }

    /**
     * Calculate compliance monitoring metrics
     */
    // private static ComplianceMetrics calculateComplianceMetrics() {
    //     // Compliance check results
    //     List<AggregateResult> complianceStats = [
    //         SELECT 
    //             COUNT(Id) totalChecks,
    //             SUM(CASE WHEN ComplianceStatus__c = 'Compliant' THEN 1 ELSE 0 END) compliantDocs,
    //             SUM(CASE WHEN ComplianceStatus__c = 'Non-Compliant' THEN 1 ELSE 0 END) nonCompliantDocs,
    //             SUM(CASE WHEN ComplianceStatus__c = 'Requires Review' THEN 1 ELSE 0 END) reviewRequiredDocs
    //         FROM DocumentLifecycleConfiguration__c 
    //         WHERE CreatedDate = LAST_N_DAYS:30
    //         AND ComplianceStatus__c != null
    //     ];
        
    //     Integer totalChecks = 0;
    //     Integer compliantDocs = 0;
    //     Integer nonCompliantDocs = 0;
    //     Integer reviewRequiredDocs = 0;
    //     Decimal complianceRate = 100;
        
    //     if (!complianceStats.isEmpty()) {
    //         AggregateResult stats = complianceStats[0];
    //         totalChecks = (Integer)stats.get('totalChecks') != null ? (Integer)stats.get('totalChecks') : 0;
    //         compliantDocs = (Integer)stats.get('compliantDocs') != null ? (Integer)stats.get('compliantDocs') : 0;
    //         nonCompliantDocs = (Integer)stats.get('nonCompliantDocs') != null ? (Integer)stats.get('nonCompliantDocs') : 0;
    //         reviewRequiredDocs = (Integer)stats.get('reviewRequiredDocs') != null ? (Integer)stats.get('reviewRequiredDocs') : 0;
            
    //         if (totalChecks > 0) {
    //             complianceRate = (Decimal.valueOf(compliantDocs) / totalChecks) * 100;
    //         }
    //     }
        
    //     // Regional compliance breakdown
    //     Map<String, RegionalComplianceMetrics> regionalCompliance = calculateRegionalCompliance();
        
    //     // Compliance violation trends
    //     List<ComplianceViolationTrend> violationTrends = calculateComplianceViolationTrends();
        
    //     // Audit trail completeness
    //     Decimal auditTrailCompleteness = calculateAuditTrailCompleteness();
        
    //     return new ComplianceMetrics(
    //         totalChecks,
    //         complianceRate,
    //         compliantDocs,
    //         nonCompliantDocs,
    //         reviewRequiredDocs,
    //         regionalCompliance,
    //         violationTrends,
    //         auditTrailCompleteness
    //     );
    // }
private static ComplianceMetrics calculateComplianceMetrics() {
    DateTime since = System.now().addDays(-30);

    // Total checks
    Integer totalChecks = [
        SELECT COUNT() 
        FROM DocumentLifecycleConfiguration__c 
        WHERE CreatedDate >= :since AND ComplianceStatus__c != null
    ];

    // Compliant
    Integer compliantDocs = [
        SELECT COUNT() 
        FROM DocumentLifecycleConfiguration__c 
        WHERE CreatedDate >= :since AND ComplianceStatus__c = 'Compliant'
    ];

    // Non-Compliant
    Integer nonCompliantDocs = [
        SELECT COUNT() 
        FROM DocumentLifecycleConfiguration__c 
        WHERE CreatedDate >= :since AND ComplianceStatus__c = 'Non-Compliant'
    ];

    // Requires Review
    Integer reviewRequiredDocs = [
        SELECT COUNT() 
        FROM DocumentLifecycleConfiguration__c 
        WHERE CreatedDate >= :since AND ComplianceStatus__c = 'Requires Review'
    ];

    Decimal complianceRate = 100;
    if (totalChecks > 0) {
        complianceRate = (Decimal.valueOf(compliantDocs) / totalChecks) * 100;
    }

    // Regional compliance breakdown
    Map<String, RegionalComplianceMetrics> regionalCompliance = calculateRegionalCompliance();

    // Compliance violation trends
    List<ComplianceViolationTrend> violationTrends = calculateComplianceViolationTrends();

    // Audit trail completeness
    Decimal auditTrailCompleteness = calculateAuditTrailCompleteness();

    return new ComplianceMetrics(
        totalChecks,
        complianceRate,
        compliantDocs,
        nonCompliantDocs,
        reviewRequiredDocs,
        regionalCompliance,
        violationTrends,
        auditTrailCompleteness
    );
}

    /**
     * Generate performance recommendations based on metrics
     */
    private static List<PerformanceRecommendation> generatePerformanceRecommendations(
        SystemMetrics systemMetrics,
        DocumentAnalytics documentAnalytics,
        UserActivityMetrics userMetrics,
        ComplianceMetrics complianceMetrics
    ) {
        List<PerformanceRecommendation> recommendations = new List<PerformanceRecommendation>();
        
        // System performance recommendations
        if (systemMetrics.avgResponseTime > RESPONSE_TIME_THRESHOLD) {
            recommendations.add(new PerformanceRecommendation(
                'SYSTEM',
                'HIGH',
                'Response Time Optimization',
                'Average response time (' + systemMetrics.avgResponseTime.setScale(2) + 's) exceeds threshold (' + RESPONSE_TIME_THRESHOLD + 's)',
                'Consider database query optimization, caching improvements, or infrastructure scaling',
                calculateResponseTimeImpact(systemMetrics.avgResponseTime)
            ));
        }
        
        if (systemMetrics.uptimePercentage < UPTIME_TARGET) {
            recommendations.add(new PerformanceRecommendation(
                'SYSTEM',
                'CRITICAL',
                'Uptime Improvement',
                'System uptime (' + systemMetrics.uptimePercentage.setScale(2) + '%) is below target (' + UPTIME_TARGET + '%)',
                'Implement redundancy measures and improve monitoring to prevent downtime',
                'High - Direct impact on user satisfaction and business continuity'
            ));
        }
        
        // Document processing recommendations
        if (documentAnalytics.successRate < 95) {
            recommendations.add(new PerformanceRecommendation(
                'PROCESSING',
                'MEDIUM',
                'Document Processing Reliability',
                'Document success rate (' + documentAnalytics.successRate.setScale(1) + '%) could be improved',
                'Review error patterns and implement additional validation and error handling',
                'Medium - Affects user experience and operational efficiency'
            ));
        }
        
        if (documentAnalytics.avgGenerationTime > 10) {
            recommendations.add(new PerformanceRecommendation(
                'PROCESSING',
                'MEDIUM',
                'Generation Time Optimization',
                'Average document generation time (' + documentAnalytics.avgGenerationTime.setScale(2) + 's) is high',
                'Optimize document generation algorithms and consider template caching',
                'Medium - Impacts user waiting time and system throughput'
            ));
        }
        
        // Compliance recommendations
        if (complianceMetrics.complianceRate < 98) {
            recommendations.add(new PerformanceRecommendation(
                'COMPLIANCE',
                'HIGH',
                'Compliance Rate Improvement',
                'Compliance rate (' + complianceMetrics.complianceRate.setScale(1) + '%) needs attention',
                'Review compliance checking algorithms and provide better user guidance',
                'High - Regulatory and legal risk implications'
            ));
        }
        
        return recommendations;
    }

    // Helper Methods
    // private static Decimal calculateUptimePercentage() {
    //     // Query system downtime events in the last 24 hours
    //     List<AggregateResult> downtimeData = [
    //         SELECT SUM(DowntimeDuration__c) totalDowntime
    //         FROM SystemDowntimeLog__c 
    //         WHERE CreatedDate = LAST_N_HOURS:24
    //     ];
        
    //     Decimal totalDowntimeMinutes = !downtimeData.isEmpty() ? 
    //         (Decimal)downtimeData[0].get('totalDowntime') : 0;
        
    //     Decimal totalMinutesIn24Hours = 24 * 60;
    //     Decimal uptimeMinutes = totalMinutesIn24Hours - (totalDowntimeMinutes != null ? totalDowntimeMinutes : 0);
        
    //     return (uptimeMinutes / totalMinutesIn24Hours) * 100;
    // }
private static Decimal calculateUptimePercentage() {
    // Get start datetime (24 hours ago)
    DateTime since = System.now().addHours(-24);

    // Query downtime in the last 24 hours
    List<AggregateResult> downtimeData = [
        SELECT SUM(DowntimeDuration__c) totalDowntime
        FROM SystemDowntimeLog__c 
        WHERE CreatedDate >= :since
    ];
    
    Decimal totalDowntimeMinutes = (downtimeData.isEmpty() || downtimeData[0].get('totalDowntime') == null) 
        ? 0 
        : (Decimal)downtimeData[0].get('totalDowntime');
    
    Decimal totalMinutesIn24Hours = 24 * 60;
    Decimal uptimeMinutes = totalMinutesIn24Hours - totalDowntimeMinutes;
    
    return (uptimeMinutes / totalMinutesIn24Hours) * 100;
}

    // private static Integer getCurrentConcurrentUsers() {
    //     // Count active sessions in the last 30 minutes
    //     List<AggregateResult> activeSessionsData = [
    //         SELECT COUNT_DISTINCT(UserId__c) activeSessions
    //         FROM UserActivity__c 
    //         WHERE CreatedDate = LAST_N_MINUTES:30
    //         AND SessionStatus__c = 'Active'
    //     ];
        
    //     return !activeSessionsData.isEmpty() ? 
    //         (Integer)activeSessionsData[0].get('activeSessions') : 0;
    // }
    
    private static Integer getCurrentConcurrentUsers() {
    // Define window (last 30 minutes)
    DateTime since = System.now().addMinutes(-30);

    // Count distinct active users
    List<AggregateResult> activeSessionsData = [
        SELECT COUNT_DISTINCT(UserId__c) activeSessions
        FROM UserActivity__c 
        WHERE CreatedDate >= :since
        AND SessionStatus__c = 'Active'
    ];
    
    return !activeSessionsData.isEmpty() && activeSessionsData[0].get('activeSessions') != null
        ? Integer.valueOf(String.valueOf(activeSessionsData[0].get('activeSessions')))
        : 0;
}


    private static Integer getMaxConcurrentUsers() {
        // Get maximum concurrent users recorded today
        List<AggregateResult> maxConcurrentData = [
            SELECT MAX(ConcurrentUsers__c) maxConcurrent
            FROM SystemPerformanceLog__c 
            WHERE CreatedDate = TODAY
        ];
        
        return !maxConcurrentData.isEmpty() ? 
            ((Decimal)maxConcurrentData[0].get('maxConcurrent')) != null ? ((Decimal)maxConcurrentData[0].get('maxConcurrent')).intValue() : 0 : 0;
    }

    private static Decimal calculateSystemHealthScore(
        Decimal avgResponseTime,
        Decimal uptimePercentage,
        Decimal responseTimeCompliance,
        Integer currentConcurrentUsers
    ) {
        Decimal healthScore = 100;
        
        // Response time factor (30% weight)
        if (avgResponseTime > RESPONSE_TIME_THRESHOLD) {
            healthScore -= ((avgResponseTime - RESPONSE_TIME_THRESHOLD) / RESPONSE_TIME_THRESHOLD) * 30;
        }
        
        // Uptime factor (40% weight)
        if (uptimePercentage < UPTIME_TARGET) {
            healthScore -= (UPTIME_TARGET - uptimePercentage) * 0.8;
        }
        
        // Response time compliance factor (20% weight)
        healthScore -= (100 - responseTimeCompliance) * 0.2;
        
        // Concurrent user load factor (10% weight)
        Decimal userLoadPercentage = (Decimal.valueOf(currentConcurrentUsers) / MAX_CONCURRENT_USERS) * 100;
        if (userLoadPercentage > 80) {
            healthScore -= (userLoadPercentage - 80) * 0.5;
        }
        
        return Math.max(0, Math.min(100, healthScore));
    }

    // Additional helper methods that are referenced but not implemented
    private static Map<String, DocumentTypeMetrics> calculateDocumentTypePerformance() {
        // Implementation placeholder
        return new Map<String, DocumentTypeMetrics>();
    }

    private static QueueMetrics calculateQueueMetrics() {
        // Implementation placeholder
        return new QueueMetrics();
    }

    private static List<VolumeDataPoint> calculateVolumeTrends() {
        // Implementation placeholder
        return new List<VolumeDataPoint>();
    }

    private static Map<String, Integer> calculateFeatureUsage() {
        // Implementation placeholder
        return new Map<String, Integer>();
    }

    private static UserAdoptionMetrics calculateUserAdoptionMetrics() {
        // Implementation placeholder
        return new UserAdoptionMetrics();
    }

    private static Decimal calculateUserEngagementScore(
        Decimal avgSessionDuration,
        Decimal avgActionsPerSession,
        Integer dailyActive,
        Integer weeklyActive,
        Integer totalActiveUsers
    ) {
        // Implementation placeholder
        return 75.0;
    }

    private static Map<String, RegionalComplianceMetrics> calculateRegionalCompliance() {
        // Implementation placeholder
        return new Map<String, RegionalComplianceMetrics>();
    }

    private static List<ComplianceViolationTrend> calculateComplianceViolationTrends() {
        // Implementation placeholder
        return new List<ComplianceViolationTrend>();
    }

    private static Decimal calculateAuditTrailCompleteness() {
        // Implementation placeholder
        return 95.0;
    }

    private static String calculateResponseTimeImpact(Decimal avgResponseTime) {
        // Implementation placeholder
        return 'Medium - Affects user experience and system performance';
    }
} 