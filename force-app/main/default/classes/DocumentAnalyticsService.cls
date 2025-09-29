/**
 * @description Essential Document Analytics - Core metrics only
 */
public with sharing class DocumentAnalyticsService {
    
    // -------------------- DOCUMENT METRICS --------------------
    
@AuraEnabled(cacheable=true)
public static Map<String, Object> getDocumentMetrics(String timeframe) {
    Map<String, Object> metrics = new Map<String, Object>();
    try {
        DateTime startDate = getStartDate(timeframe);
        
        // Query total documents + average processing time
        List<AggregateResult> docStats = [
            SELECT COUNT(Id) totalDocs, 
                   AVG(Processing_Time_Seconds__c) avgProcessingTime
            FROM Document_Generation_Log__c
            WHERE CreatedDate >= :startDate
        ];
        
        // Query completed documents separately
        Integer completedDocs = [
            SELECT COUNT()
            FROM Document_Generation_Log__c
            WHERE CreatedDate >= :startDate
            AND Status__c = 'COMPLETED'
        ];
        
        if (!docStats.isEmpty()) {
            AggregateResult stats = docStats[0];
            metrics.put('totalDocuments', (Integer)stats.get('totalDocs'));
            metrics.put('completedDocuments', completedDocs);
            metrics.put('averageProcessingTime', (Decimal)stats.get('avgProcessingTime'));
        }
        
        metrics.put('success', true);
        
    } catch (Exception e) {
        metrics.put('success', false);
        metrics.put('error', e.getMessage());
    }
    return metrics;
}

    // -------------------- USAGE STATISTICS --------------------
    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getUsageStatistics() {
        Map<String, Object> usage = new Map<String, Object>();
        try {
            // Document generation usage
            Integer todayDocs = [
                SELECT COUNT() 
                FROM Document_Generation_Log__c 
                WHERE DAY_ONLY(CreatedDate) = TODAY
            ];
            
            // E-signature usage
            Integer todaySignatures = [
                SELECT COUNT() 
                FROM Signature_Request__c 
                WHERE DAY_ONLY(CreatedDate) = TODAY
            ];
            
            usage.put('documentsToday', todayDocs);
            usage.put('signaturesToday', todaySignatures);
            usage.put('success', true);
            
        } catch (Exception e) {
            usage.put('success', false);
            usage.put('error', e.getMessage());
        }
        return usage;
    }
    
    // -------------------- TIMEFRAME UTILITY --------------------
    
    private static DateTime getStartDate(String timeframe) {
        switch on timeframe {
            when 'TODAY' {
                return DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0));
            }
            when 'WEEK' {
                return DateTime.now().addDays(-7);
            }
            when 'MONTH' {
                return DateTime.now().addDays(-30);
            }
            when else {
                return DateTime.now().addDays(-7);
            }
        }
    }
}
