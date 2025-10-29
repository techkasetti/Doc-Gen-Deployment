public with sharing class ProductionAnalytics {

    // ===========================
    // Data Transfer Object (DTO)
    // ===========================
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

        public ProductionMetrics() {
            documentsGenerated     = 0;
            signaturesCompleted    = 0;
            complianceViolations   = 0;
            averageGenerationTime  = 0;
            systemUptime           = 99.5;
            complianceScore        = 100;
            documentsByType        = new Map<String, Integer>();
            documentsByRegion      = new Map<String, Integer>();
            performanceMetrics     = new List<Map<String, Object>>();
            recentActivity         = new List<Map<String, Object>>();
        }
    }

    // ===========================
    // Public API
    // ===========================
    @AuraEnabled(cacheable=true)
    public static ProductionMetrics getDashboardMetrics(String timeframe) {
        ProductionMetrics metrics = new ProductionMetrics();

        try {
            DateTime startTime = getStartTimeForTimeframe(timeframe);
            DateTime endTime   = DateTime.now();

            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

            // Documents generated
            if (gd.containsKey('DocumentLifecycleConfiguration__c')) {
                metrics.documentsGenerated = Database.countQuery(
                    'SELECT COUNT() FROM DocumentLifecycleConfiguration__c ' +
                    'WHERE CreatedDate >= ' + formatDateTimeForSOQL(startTime) +
                    ' AND CreatedDate <= ' + formatDateTimeForSOQL(endTime)
                );
            } else {
                metrics.documentsGenerated = 0;
            }

            // Signatures completed
            if (gd.containsKey('Signature_Request__c')) {
                metrics.signaturesCompleted = Database.countQuery(
                    'SELECT COUNT() FROM Signature_Request__c ' +
                    'WHERE Status__c = \'Signed\' ' +
                    'AND SignedDate__c >= ' + formatDateTimeForSOQL(startTime) +
                    ' AND SignedDate__c <= ' + formatDateTimeForSOQL(endTime)
                );
            } else {
                metrics.signaturesCompleted = 0;
            }

            // Compliance violations (OPEN + HIGH/CRITICAL)
            if (gd.containsKey('DocumentComplianceFinding__c')) {
                metrics.complianceViolations = Database.countQuery(
                    'SELECT COUNT() FROM DocumentComplianceFinding__c ' +
                    'WHERE Status__c = \'OPEN\' ' +
                    'AND Severity__c IN (\'HIGH\', \'CRITICAL\') ' +
                    'AND CreatedDate >= ' + formatDateTimeForSOQL(startTime)
                );
            } else {
                metrics.complianceViolations = 0;
            }

            // Average generation time
            if (gd.containsKey('DocumentLifecycleConfiguration__c')) {
                List<AggregateResult> avgTime = Database.query(
                    'SELECT AVG(Processing_Time__c) avgTime ' +
                    'FROM DocumentLifecycleConfiguration__c ' +
                    'WHERE Processing_Time__c != null ' +
                    'AND CreatedDate >= ' + formatDateTimeForSOQL(startTime)
                );

                if (!avgTime.isEmpty() && avgTime[0].get('avgTime') != null) {
                    Object v = avgTime[0].get('avgTime');
                    metrics.averageGenerationTime = (v instanceof Decimal)
                        ? (Decimal) v
                        : Decimal.valueOf(String.valueOf(v));
                } else {
                    metrics.averageGenerationTime = 0;
                }
            } else {
                metrics.averageGenerationTime = 0;
            }

            // System uptime (heuristic)
            metrics.systemUptime = calculateSystemUptime(startTime, endTime);

            // Compliance score (heuristic)
            metrics.complianceScore = calculateComplianceScore(startTime, endTime);

            // Documents by type/region
            metrics.documentsByType   = getDocumentsByType(startTime, endTime);
            metrics.documentsByRegion = getDocumentsByRegion(startTime, endTime);

            // Performance metrics
            metrics.performanceMetrics = getPerformanceMetrics(startTime, endTime);

            // Recent activity
            metrics.recentActivity = getRecentActivity(20);
        }
        catch (Exception e) {
            System.debug('Error generating dashboard metrics: ' + e.getMessage());
            metrics = getDefaultMetrics();
        }

        return metrics;
    }

    public static void generateDailyReport() {
        try {
            ProductionMetrics dailyMetrics = getDashboardMetrics('TODAY');

            // Persist daily report (if object exists)
            if (Schema.getGlobalDescribe().containsKey('SystemReport__c')) {
                SystemReport__c dailyReport = new SystemReport__c();
                dailyReport.ReportType__c            = 'DAILY_PRODUCTION';
                dailyReport.ReportDate__c            = Date.today();
                dailyReport.DocumentsGenerated__c    = dailyMetrics.documentsGenerated;
                dailyReport.SignaturesCompleted__c   = dailyMetrics.signaturesCompleted;
                dailyReport.ComplianceViolations__c  = dailyMetrics.complianceViolations;
                dailyReport.AverageGenerationTime__c = dailyMetrics.averageGenerationTime;
                dailyReport.SystemUptime__c          = dailyMetrics.systemUptime;
                dailyReport.ComplianceScore__c       = dailyMetrics.complianceScore;
                dailyReport.ReportData__c            = JSON.serialize(dailyMetrics);
                insert dailyReport;
            }

            // Email
            sendDailyReportEmail(dailyMetrics);
            System.debug('Daily production report generated successfully');
        }
        catch (Exception e) {
            System.debug('Failed to generate daily report: ' + e.getMessage());
            createSystemAlert('DAILY_REPORT_FAILURE', e.getMessage(), 'HIGH');
        }
    }

    public static void generateWeeklyReport() {
        try {
            ProductionMetrics weeklyMetrics = getDashboardMetrics('THIS_WEEK');
            Map<String, Object> weeklyTrends = calculateWeeklyTrends();

            if (Schema.getGlobalDescribe().containsKey('SystemReport__c')) {
                SystemReport__c weeklyReport = new SystemReport__c();
                weeklyReport.ReportType__c            = 'WEEKLY_PRODUCTION';
                weeklyReport.ReportDate__c            = Date.today();
                weeklyReport.DocumentsGenerated__c    = weeklyMetrics.documentsGenerated;
                weeklyReport.SignaturesCompleted__c   = weeklyMetrics.signaturesCompleted;
                weeklyReport.ComplianceViolations__c  = weeklyMetrics.complianceViolations;
                weeklyReport.AverageGenerationTime__c = weeklyMetrics.averageGenerationTime;
                weeklyReport.SystemUptime__c          = weeklyMetrics.systemUptime;
                weeklyReport.ComplianceScore__c       = weeklyMetrics.complianceScore;
                weeklyReport.ReportData__c            =
                    JSON.serialize(new Map<String, Object>{
                        'metrics' => weeklyMetrics,
                        'trends'  => weeklyTrends
                    });
                insert weeklyReport;
            }

            System.debug('Weekly production report generated successfully');
        }
        catch (Exception e) {
            System.debug('Failed to generate weekly report: ' + e.getMessage());
            createSystemAlert('WEEKLY_REPORT_FAILURE', e.getMessage(), 'HIGH');
        }
    }

    public static void generateMonthlyExecutiveReport() {
        try {
            ProductionMetrics monthlyMetrics = getDashboardMetrics('THIS_MONTH');
            Map<String, Object> executiveInsights = calculateExecutiveInsights();

            if (Schema.getGlobalDescribe().containsKey('ExecutiveReport__c')) {
                ExecutiveReport__c execReport = new ExecutiveReport__c();

                Date today        = Date.today();
                Date firstOfMonth = Date.newInstance(today.year(), today.month(), 1);

                execReport.ReportMonth__c          = firstOfMonth;
                execReport.DocumentsGenerated__c   = monthlyMetrics.documentsGenerated;
                execReport.SignaturesCompleted__c  = monthlyMetrics.signaturesCompleted;
                execReport.ComplianceScore__c      = monthlyMetrics.complianceScore;
                execReport.SystemUptime__c         = monthlyMetrics.systemUptime;
                execReport.ExecutiveInsights__c    = JSON.serialize(executiveInsights);
                execReport.ReportData__c           = JSON.serialize(monthlyMetrics);

                insert execReport;
            }

            sendExecutiveReportEmail(monthlyMetrics, executiveInsights);
            System.debug('Monthly executive report generated successfully');
        }
        catch (Exception e) {
            System.debug('Failed to generate monthly executive report: ' + e.getMessage());
            createSystemAlert('EXECUTIVE_REPORT_FAILURE', e.getMessage(), 'CRITICAL');
        }
    }

    // ===========================
    // Helpers & Utilities
    // ===========================
    private static DateTime getStartTimeForTimeframe(String timeframe) {
        if (String.isBlank(timeframe)) return DateTime.now().addHours(-24);

        String tf = timeframe != null ? timeframe.trim().toUpperCase() : '';

        if (tf == 'TODAY') {
            Date d = Date.today();
            return DateTime.newInstance(d.year(), d.month(), d.day(), 0, 0, 0);
        } else if (tf == 'THIS_WEEK' || tf == 'LAST_7_DAYS') {
            return DateTime.now().addDays(-7);
        } else if (tf == 'THIS_MONTH') {
            Date d = Date.today();
            Date firstDay = Date.newInstance(d.year(), d.month(), 1);
            return DateTime.newInstance(firstDay.year(), firstDay.month(), firstDay.day(), 0, 0, 0);
        } else if (tf == 'LAST_30_DAYS') {
            return DateTime.now().addDays(-30);
        } else {
            return DateTime.now().addHours(-24);
        }
    }

    private static Decimal calculateSystemUptime(DateTime startTime, DateTime endTime) {
        try {
            Decimal totalHours = 24;
            if (startTime != null && endTime != null) {
                totalHours = (endTime.getTime() - startTime.getTime()) / (1000 * 60 * 60);
            }

            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            Integer systemErrors = 0;

            if (gd.containsKey('SystemAlert__c')) {
                systemErrors = Database.countQuery(
                    'SELECT COUNT() FROM SystemAlert__c ' +
                    'WHERE Priority__c = \'CRITICAL\' ' +
                    'AND Status__c = \'ACTIVE\' ' +
                    'AND CreatedDate >= ' + formatDateTimeForSOQL(startTime) +
                    ' AND CreatedDate <= ' + formatDateTimeForSOQL(endTime)
                );
            }

            // Simplified: 1 hour downtime per critical active alert
            Decimal downtimeHours = systemErrors * 1;
            Decimal uptime = totalHours > 0
                ? ((totalHours - downtimeHours) / totalHours) * 100
                : 100;

            return Math.max(0, Math.min(100, uptime));
        }
        catch (Exception e) {
            return 99.5;
        }
    }

    private static Decimal calculateComplianceScore(DateTime startTime, DateTime endTime) {
        try {
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

            Integer totalDocuments     = 0;
            Integer compliantDocuments = 0;

            if (gd.containsKey('DocumentLifecycleConfiguration__c')) {
                totalDocuments = Database.countQuery(
                    'SELECT COUNT() FROM DocumentLifecycleConfiguration__c ' +
                    'WHERE CreatedDate >= ' + formatDateTimeForSOQL(startTime) +
                    ' AND CreatedDate <= ' + formatDateTimeForSOQL(endTime)
                );

                compliantDocuments = Database.countQuery(
                    'SELECT COUNT() FROM DocumentLifecycleConfiguration__c ' +
                    'WHERE ComplianceStatus__c = \'Compliant\' ' +
                    'AND CreatedDate >= ' + formatDateTimeForSOQL(startTime) +
                    ' AND CreatedDate <= ' + formatDateTimeForSOQL(endTime)
                );
            }

            if (totalDocuments == 0) return 100;
            return (Decimal.valueOf(compliantDocuments) / Decimal.valueOf(totalDocuments)) * 100;
        }
        catch (Exception e) {
            return 95.0;
        }
    }

    private static Map<String, Integer> getDocumentsByType(DateTime startTime, DateTime endTime) {
        Map<String, Integer> typeCount = new Map<String, Integer>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

        if (!gd.containsKey('DocumentLifecycleConfiguration__c')) return typeCount;

        try {
            List<AggregateResult> results = Database.query(
                'SELECT ContractType__c type, COUNT(Id) totalcount ' +
                'FROM DocumentLifecycleConfiguration__c ' +
                'WHERE CreatedDate >= ' + formatDateTimeForSOQL(startTime) +
                ' AND CreatedDate <= ' + formatDateTimeForSOQL(endTime) +
                ' GROUP BY ContractType__c'
            );

            for (AggregateResult ar : results) {
                Object key = ar.get('type');
                Object cnt = ar.get('totalcount');

                String sk  = key != null ? String.valueOf(key) : 'unknown';
                Integer ic = (cnt instanceof Decimal)
                    ? ((Decimal) cnt).intValue()
                    : (cnt instanceof Integer ? (Integer) cnt : Integer.valueOf(String.valueOf(cnt)));

                typeCount.put(sk, ic);
            }
        } catch (Exception e) {
            // ignore and return empty
        }

        return typeCount;
    }

    private static Map<String, Integer> getDocumentsByRegion(DateTime startTime, DateTime endTime) {
        Map<String, Integer> regionCount = new Map<String, Integer>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

        if (!gd.containsKey('DocumentLifecycleConfiguration__c')) return regionCount;

        try {
            List<AggregateResult> results = Database.query(
                'SELECT Region__c region, COUNT(Id) totalcount ' +
                'FROM DocumentLifecycleConfiguration__c ' +
                'WHERE CreatedDate >= ' + formatDateTimeForSOQL(startTime) +
                ' AND CreatedDate <= ' + formatDateTimeForSOQL(endTime) +
                ' GROUP BY Region__c'
            );

            for (AggregateResult ar : results) {
                Object key = ar.get('region');
                Object cnt = ar.get('totalcount');

                String sk  = key != null ? String.valueOf(key) : 'unknown';
                Integer ic = (cnt instanceof Decimal)
                    ? ((Decimal) cnt).intValue()
                    : (cnt instanceof Integer ? (Integer) cnt : Integer.valueOf(String.valueOf(cnt)));

                regionCount.put(sk, ic);
            }
        } catch (Exception e) {
            // ignore
        }

        return regionCount;
    }

    private static List<Map<String, Object>> getPerformanceMetrics(DateTime startTime, DateTime endTime) {
        List<Map<String, Object>> metrics = new List<Map<String, Object>>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

        if (!gd.containsKey('DocumentLifecycleConfiguration__c')) return metrics;

        try {
            List<AggregateResult> perfResults = Database.query(
                'SELECT AVG(Processing_Time__c) avgTime, ' +
                'MAX(Processing_Time__c) maxTime, ' +
                'MIN(Processing_Time__c) minTime, ' +
                'COUNT(Id) totalCount ' +
                'FROM DocumentLifecycleConfiguration__c ' +
                'WHERE Processing_Time__c != null ' +
                'AND CreatedDate >= ' + formatDateTimeForSOQL(startTime) +
                ' AND CreatedDate <= ' + formatDateTimeForSOQL(endTime)
            );

            if (!perfResults.isEmpty()) {
                AggregateResult r = perfResults[0];

                Map<String, Object> row = new Map<String, Object>();
                row.put('metric',  'Document Generation Time');
                row.put('average', r.get('avgTime'));
                row.put('maximum', r.get('maxTime'));
                row.put('minimum', r.get('minTime'));
                row.put('count',   r.get('totalCount'));
                row.put('unit',    'seconds');

                metrics.add(row);
            }
        } catch (Exception e) {
            // ignore
        }

        return metrics;
    }

    private static List<Map<String, Object>> getRecentActivity(Integer limitCount) {
        List<Map<String, Object>> activities = new List<Map<String, Object>>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

        if (!gd.containsKey('AuditTrail__c')) return activities;

        try {
            Integer limitVal = (limitCount == null || limitCount <= 0) ? 20 : limitCount;

            List<AuditTrail__c> recentAudits = [
                SELECT Id, Action__c, CreatedDate, CreatedBy.Name, RelatedRecordId__c
                FROM AuditTrail__c
                ORDER BY CreatedDate DESC
                LIMIT :limitVal
            ];

            for (AuditTrail__c audit : recentAudits) {
                Map<String, Object> m = new Map<String, Object>();
                m.put('id', audit.Id);

                String createdByName = (audit.CreatedBy != null) ? audit.CreatedBy.Name : 'System';
                m.put('message',
                    (audit.Action__c != null ? audit.Action__c : '') + ' by ' + createdByName
                );

                m.put('timestamp',
                    audit.CreatedDate != null ? audit.CreatedDate.formatGMT('yyyy-MM-dd HH:mm:ss') : null
                );

                m.put('icon', getActivityIcon(audit.Action__c));

                activities.add(m);
            }
        }
        catch (Exception e) {
            // ignore and return empty
        }

        return activities;
    }

    private static String getActivityIcon(String action) {
        if (action == null) return 'standard:event';
        if (action.contains('Document'))   return 'standard:document';
        if (action.contains('Signature'))  return 'standard:signature';
        if (action.contains('Compliance')) return 'standard:approval';
        return 'standard:event';
    }

    // ---------- Trends & Insights ----------
    private static Map<String, Object> calculateWeeklyTrends() {
        DateTime thisWeekStart = DateTime.now().addDays(-7);
        DateTime lastWeekStart = DateTime.now().addDays(-14);

        Integer thisWeekDocs = 0;
        Integer lastWeekDocs = 0;

        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

        if (gd.containsKey('DocumentLifecycleConfiguration__c')) {
            thisWeekDocs = Database.countQuery(
                'SELECT COUNT() FROM DocumentLifecycleConfiguration__c ' +
                'WHERE CreatedDate >= ' + formatDateTimeForSOQL(thisWeekStart)
            );

            lastWeekDocs = Database.countQuery(
                'SELECT COUNT() FROM DocumentLifecycleConfiguration__c ' +
                'WHERE CreatedDate >= ' + formatDateTimeForSOQL(lastWeekStart) +
                ' AND CreatedDate < ' + formatDateTimeForSOQL(thisWeekStart)
            );
        }

        Decimal docTrend = 0;
        if (lastWeekDocs > 0) {
            docTrend = ((thisWeekDocs - lastWeekDocs) / Decimal.valueOf(lastWeekDocs)) * 100;
        }

        return new Map<String, Object>{
            'documentTrend'  => docTrend,
            'trendDirection' => (docTrend > 0 ? 'up' : (docTrend < 0 ? 'down' : 'stable'))
        };
    }

    private static Map<String, Object> calculateExecutiveInsights() {
        Map<String, Object> insights = new Map<String, Object>();

        insights.put('topDocumentType',      getTopDocumentType());
        insights.put('performanceSummary',   getPerformanceSummary());
        insights.put('complianceHighlights', getComplianceHighlights());
        insights.put('systemRecommendations', getSystemRecommendations());
        insights.put('costSavings',          calculateCostSavings());
        insights.put('userAdoption',         calculateUserAdoption());
        insights.put('riskAssessment',       performRiskAssessment());

        return insights;
    }

    private static Map<String, Object> getTopDocumentType() {
        Map<String, Object> out = new Map<String, Object>{
            'type' => 'N/A', 'count' => 0, 'percentage' => 0
        };

        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey('DocumentLifecycleConfiguration__c')) return out;

        try {
            List<AggregateResult> topType = Database.query(
                'SELECT ContractType__c type, COUNT(Id) cnt ' +
                'FROM DocumentLifecycleConfiguration__c ' +
                'WHERE CreatedDate = LAST_N_DAYS:30 ' +
                'GROUP BY ContractType__c ' +
                'ORDER BY COUNT(Id) DESC LIMIT 1'
            );

            if (!topType.isEmpty()) {
                Object type = topType[0].get('type');
                Object cnt  = topType[0].get('cnt');

                String  stype = type != null ? String.valueOf(type) : 'N/A';
                Integer icnt  = (cnt instanceof Decimal)
                    ? ((Decimal) cnt).intValue()
                    : Integer.valueOf(String.valueOf(cnt));

                Decimal pct = calculateTypePercentage(stype);

                out.put('type',       stype);
                out.put('count',      icnt);
                out.put('percentage', pct);
            }
        } catch (Exception e) {
            // ignore
        }

        return out;
    }

    private static Map<String, Object> getPerformanceSummary() {
        Map<String, Object> out = new Map<String, Object>();

        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Decimal  avgTime  = 0;
        Integer  totalDoc = 0;

        if (gd.containsKey('DocumentLifecycleConfiguration__c')) {
            try {
                List<AggregateResult> perfSummary = Database.query(
                    'SELECT AVG(Processing_Time__c) avgTime, COUNT(Id) cnt ' +
                    'FROM DocumentLifecycleConfiguration__c ' +
                    'WHERE CreatedDate = LAST_N_DAYS:30 ' +
                    'AND Processing_Time__c != null'
                );

                if (!perfSummary.isEmpty()) {
                    Object a = perfSummary[0].get('avgTime');
                    Object c = perfSummary[0].get('cnt');

                    avgTime  = (a != null)
                        ? (a instanceof Decimal ? (Decimal) a : Decimal.valueOf(String.valueOf(a)))
                        : 0;

                    totalDoc = (c != null)
                        ? (c instanceof Decimal ? ((Decimal) c).intValue() : Integer.valueOf(String.valueOf(c)))
                        : 0;
                }
            } catch (Exception e) {
                // ignore
            }
        }

        out.put('averageProcessingTime',   avgTime);
        out.put('totalDocumentsProcessed', totalDoc);
        out.put('slaCompliance',           avgTime < 5 ? 100 : ((5 / (avgTime > 0 ? avgTime : 5)) * 100));
        out.put('performanceGrade',        getPerformanceGrade(avgTime));

        return out;
    }

    private static Map<String, Object> getComplianceHighlights() {
        Map<String, Object> out = new Map<String, Object>{
            'totalViolations'   => 0,
            'resolvedViolations'=> 0,
            'resolutionRate'    => 100,
            'complianceStatus'  => 'EXCELLENT'
        };

        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey('DocumentComplianceFinding__c')) return out;

        try {
            Integer totalViolations = Database.countQuery(
                'SELECT COUNT() FROM DocumentComplianceFinding__c ' +
                'WHERE CreatedDate = LAST_N_DAYS:30'
            );

            Integer resolvedViolations = Database.countQuery(
                'SELECT COUNT() FROM DocumentComplianceFinding__c ' +
                'WHERE Status__c = \'RESOLVED\' ' +
                'AND CreatedDate = LAST_N_DAYS:30'
            );

            Decimal resolutionRate = totalViolations > 0
                ? (resolvedViolations * 100.0 / totalViolations)
                : 100;

            String status = (totalViolations == 0)
                ? 'EXCELLENT'
                : (totalViolations < 5 ? 'GOOD' : 'NEEDS_ATTENTION');

            out.put('totalViolations',    totalViolations);
            out.put('resolvedViolations', resolvedViolations);
            out.put('resolutionRate',     resolutionRate);
            out.put('complianceStatus',   status);
        } catch (Exception e) {
            // ignore
        }

        return out;
    }

    private static List<String> getSystemRecommendations() {
        List<String> recommendations = new List<String>();

        Decimal avgTime = getAverageProcessingTime();
        if (avgTime > 5) {
            recommendations.add('Consider optimizing document generation templates to improve performance');
        }

        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

        if (gd.containsKey('DocumentComplianceFinding__c')) {
            Integer openViolations = Database.countQuery(
                'SELECT COUNT() FROM DocumentComplianceFinding__c ' +
                'WHERE Status__c = \'OPEN\''
            );
            if (openViolations > 0) {
                recommendations.add('Address ' + openViolations + ' open compliance violations');
            }
        }

        Map<String, Integer> regionUsage = getDocumentsByRegion(DateTime.now().addDays(-30), DateTime.now());
        if (regionUsage.size() < 3) {
            recommendations.add('Consider expanding document generation to additional regions');
        }

        return recommendations;
    }

    private static Map<String, Object> calculateCostSavings() {
        Map<String, Object> out = new Map<String, Object>();

        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Integer docsGenerated = 0;

        if (gd.containsKey('DocumentLifecycleConfiguration__c')) {
            docsGenerated = Database.countQuery(
                'SELECT COUNT() FROM DocumentLifecycleConfiguration__c ' +
                'WHERE CreatedDate = LAST_N_DAYS:30'
            );
        }

        Decimal costPerManualDoc = 25.0;
        Decimal totalSavings     = docsGenerated * costPerManualDoc;

        out.put('monthlyDocuments',    docsGenerated);
        out.put('costPerDocument',     costPerManualDoc);
        out.put('totalMonthlySavings', totalSavings);
        out.put('annualizedSavings',   totalSavings * 12);

        return out;
    }

    private static Map<String, Object> calculateUserAdoption() {
        Map<String, Object> out = new Map<String, Object>{
            'activeUsers'       => 0,
            'totalLicensedUsers'=> 0,
            'adoptionRate'      => 0,
            'adoptionStatus'    => 'UNKNOWN'
        };

        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();

        try {
            Set<Id> activeUsers = new Set<Id>();

            if (gd.containsKey('DocumentLifecycleConfiguration__c')) {
                for (SObject s : Database.query(
                    'SELECT CreatedById FROM DocumentLifecycleConfiguration__c ' +
                    'WHERE CreatedDate = LAST_N_DAYS:30'
                )) {
                    Object cb = s.get('CreatedById');
                    if (cb != null) activeUsers.add((Id) cb);
                }
            }

            Integer totalLicensedUsers = Database.countQuery(
                'SELECT COUNT() FROM User ' +
                'WHERE IsActive = true AND Profile.Name LIKE \'%Document%\''
            );

            Decimal adoptionRate = totalLicensedUsers > 0
                ? (activeUsers.size() * 100.0 / totalLicensedUsers)
                : 0;

            String adoptionStatus = (adoptionRate > 80)
                ? 'EXCELLENT'
                : (adoptionRate > 60 ? 'GOOD' : 'NEEDS_IMPROVEMENT');

            out.put('activeUsers',        activeUsers.size());
            out.put('totalLicensedUsers', totalLicensedUsers);
            out.put('adoptionRate',       adoptionRate);
            out.put('adoptionStatus',     adoptionStatus);
        } catch (Exception e) {
            // ignore
        }

        return out;
    }

    private static Map<String, Object> performRiskAssessment() {
        Map<String, Object> out = new Map<String, Object>{
            'criticalViolations' => 0,
            'highViolations'     => 0,
            'overallRiskLevel'   => 'LOW',
            'riskScore'          => 0
        };

        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey('DocumentComplianceFinding__c')) return out;

        try {
            Integer criticalViolations = Database.countQuery(
                'SELECT COUNT() FROM DocumentComplianceFinding__c ' +
                'WHERE Severity__c = \'CRITICAL\' AND Status__c = \'OPEN\''
            );

            Integer highViolations = Database.countQuery(
                'SELECT COUNT() FROM DocumentComplianceFinding__c ' +
                'WHERE Severity__c = \'HIGH\' AND Status__c = \'OPEN\''
            );

            String riskLevel = 'LOW';
            if (criticalViolations > 0)       riskLevel = 'CRITICAL';
            else if (highViolations > 3)      riskLevel = 'HIGH';
            else if (highViolations > 0)      riskLevel = 'MEDIUM';

            Integer riskScore = calculateRiskScore(criticalViolations, highViolations);

            out.put('criticalViolations', criticalViolations);
            out.put('highViolations',     highViolations);
            out.put('overallRiskLevel',   riskLevel);
            out.put('riskScore',          riskScore);
        } catch (Exception e) {
            // ignore
        }

        return out;
    }

    // ---------- Small helpers ----------
    private static ProductionMetrics getDefaultMetrics() {
        return new ProductionMetrics();
    }

    private static Decimal getAverageProcessingTime() {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey('DocumentLifecycleConfiguration__c')) return 3.0;

        try {
            List<AggregateResult> avgResult = Database.query(
                'SELECT AVG(Processing_Time__c) avgTime ' +
                'FROM DocumentLifecycleConfiguration__c ' +
                'WHERE Processing_Time__c != null ' +
                'AND CreatedDate = LAST_N_DAYS:7'
            );

            if (!avgResult.isEmpty() && avgResult[0].get('avgTime') != null) {
                Object v = avgResult[0].get('avgTime');
                return (v instanceof Decimal) ? (Decimal) v : Decimal.valueOf(String.valueOf(v));
            }
        } catch (Exception e) {
            // ignore
        }

        return 3.0;
    }

    private static String getPerformanceGrade(Decimal avgTime) {
        if (avgTime < 2) return 'A+';
        if (avgTime < 3) return 'A';
        if (avgTime < 5) return 'B';
        if (avgTime < 8) return 'C';
        return 'D';
    }

    private static Decimal calculateTypePercentage(String docType) {
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        if (!gd.containsKey('DocumentLifecycleConfiguration__c')) return 0;

        try {
            Integer typeCount = Database.countQuery(
                'SELECT COUNT() FROM DocumentLifecycleConfiguration__c ' +
                'WHERE ContractType__c = \'' + String.escapeSingleQuotes(docType) + '\' ' +
                'AND CreatedDate = LAST_N_DAYS:30'
            );

            Integer totalCount = Database.countQuery(
                'SELECT COUNT() FROM DocumentLifecycleConfiguration__c ' +
                'WHERE CreatedDate = LAST_N_DAYS:30'
            );

            return totalCount > 0 ? (typeCount * 100.0 / totalCount) : 0;
        } catch (Exception e) {
            return 0;
        }
    }

    private static Integer calculateRiskScore(Integer critical, Integer high) {
        return (critical * 10) + (high * 5);
    }

    private static void sendDailyReportEmail(ProductionMetrics metrics) {
        try {
            List<User> adminUsers = [
                SELECT Email FROM User
                WHERE Profile.Name = 'System Administrator' AND IsActive = true
            ];
            if (adminUsers.isEmpty()) return;

            String emailBody = generateDailyEmailBody(metrics);

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> tos = new List<String>();
            for (User u : adminUsers) if (u.Email != null) tos.add(u.Email);
            if (tos.isEmpty()) return;

            mail.setToAddresses(tos);
            mail.setSubject('Daily Production Report - ' + Date.today().format());
            mail.setHtmlBody(emailBody);

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        } catch (Exception e) {
            System.debug('Failed to send daily report email: ' + e.getMessage());
        }
    }

    private static void sendExecutiveReportEmail(ProductionMetrics metrics, Map<String, Object> insights) {
        try {
            List<User> execUsers = [
                SELECT Email FROM User
                WHERE UserRole.Name LIKE '%Executive%' AND IsActive = true
            ];
            if (execUsers.isEmpty()) return;

            String emailBody = generateExecutiveEmailBody(metrics, insights);

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> tos = new List<String>();
            for (User u : execUsers) if (u.Email != null) tos.add(u.Email);
            if (tos.isEmpty()) return;

            mail.setToAddresses(tos);
           
            mail.setHtmlBody(emailBody);

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        } catch (Exception e) {
            System.debug('Failed to send executive report email: ' + e.getMessage());
        }
    }

    private static String generateDailyEmailBody(ProductionMetrics metrics) {
        return ''
            + 'Daily Production Report - ' + Date.today().format() + '\n\n'
            + 'Documents Generated: '     + metrics.documentsGenerated + '\n'
            + 'Signatures Completed: '    + metrics.signaturesCompleted + '\n'
            + 'Compliance Score: '        + (metrics.complianceScore != null ? metrics.complianceScore.setScale(1) : 0) + '%\n'
            + 'Average Generation Time: ' + (metrics.averageGenerationTime != null ? metrics.averageGenerationTime.setScale(2) : 0) + 's\n'
            + 'System Uptime: '           + (metrics.systemUptime != null ? metrics.systemUptime.setScale(2) : 0) + '%\n';
    }

    private static String generateExecutiveEmailBody(ProductionMetrics metrics, Map<String, Object> insights) {
        Map<String, Object> costSavings = (insights != null && insights.containsKey('costSavings'))
            ? (Map<String, Object>) insights.get('costSavings')
            : new Map<String, Object>();

        Map<String, Object> userAdoption = (insights != null && insights.containsKey('userAdoption'))
            ? (Map<String, Object>) insights.get('userAdoption')
            : new Map<String, Object>();

        String monthlySavings = costSavings.containsKey('totalMonthlySavings')
            ? String.valueOf(costSavings.get('totalMonthlySavings')) : '0';

        String adoptionRate = userAdoption.containsKey('adoptionRate')
            ? String.valueOf(userAdoption.get('adoptionRate')) : '0';

        String monthName = DateTime.now().format('MMMM yyyy');

        return ''
            + 'Executive Summary - ' + monthName + '\n\n'
            + 'Key Performance Indicators\n'
            + '- Documents Generated: ' + metrics.documentsGenerated + '\n'
            + '- Compliance Score: '    + (metrics.complianceScore != null ? metrics.complianceScore.setScale(1) : 0) + '%\n'
            + '- System Uptime: '       + (metrics.systemUptime != null ? metrics.systemUptime.setScale(2) : 0) + '%\n\n'
            + 'Business Impact\n'
            + '- Monthly Cost Savings: $' + monthlySavings + '\n'
            + '- User Adoption Rate: '    + adoptionRate + '%\n';
    }

    private static void createSystemAlert(String alertType, String message, String priority) {
        try {
            if (!Schema.getGlobalDescribe().containsKey('SystemAlert__c')) return;

            SystemAlert__c alert = new SystemAlert__c();
            alert.AlertType__c = alertType;
            alert.Message__c   = message;
            alert.Priority__c  = priority;
            alert.Status__c    = 'ACTIVE';
            alert.AlertDate__c = DateTime.now();

            insert alert;
        } catch (Exception e) {
            System.debug('Failed to create system alert: ' + e.getMessage());
        }
    }

    // Utility: format DateTime as a SOQL literal with quotes
    private static String formatDateTimeForSOQL(DateTime dt) {
        if (dt == null) dt = DateTime.now();
        return '\'' + dt.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'') + '\'';
    }
}