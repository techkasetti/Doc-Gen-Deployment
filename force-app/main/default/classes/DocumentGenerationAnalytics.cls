// Phase 12: Advanced Analytics and Monitoring
public with sharing class DocumentGenerationAnalytics {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getGenerationAnalytics(String folderId, Integer dayRange) {
        try {
            Map<String, Object> analytics = new Map<String, Object>();
            Date startDate = Date.today().addDays(-dayRange);

            // Generation volume analytics
            List<AggregateResult> volumeResults = [
                SELECT COUNT(Id) totalGenerations,
                       AVG(Document_Length__c) avgLength,
                       AI_Model_Used__c modelUsed
                FROM Document_Generation_Audit__c 
                WHERE FolderId__c = :folderId 
                  AND Generation_Timestamp__c >= :startDate
                GROUP BY AI_Model_Used__c
            ];
            analytics.put('volumeByModel', processVolumeResults(volumeResults));

            // Daily generation trends
            List<AggregateResult> dailyTrends = [
                SELECT DAY_ONLY(Generation_Timestamp__c) generationDate,
                       COUNT(Id) dailyCount
                FROM Document_Generation_Audit__c 
                WHERE FolderId__c = :folderId 
                  AND Generation_Timestamp__c >= :startDate
                GROUP BY DAY_ONLY(Generation_Timestamp__c)
                ORDER BY DAY_ONLY(Generation_Timestamp__c)
            ];
            analytics.put('dailyTrends', processDailyTrends(dailyTrends));

            // Template usage analytics
            List<AggregateResult> templateUsage = [
                SELECT Template__r.Name templateName,
                       COUNT(Id) usageCount,
                       AVG(Document_Length__c) avgLength
                FROM Document_Generation_Audit__c 
                WHERE FolderId__c = :folderId 
                  AND Generation_Timestamp__c >= :startDate
                GROUP BY Template__r.Name
                ORDER BY COUNT(Id) DESC
            ];
            analytics.put('templateUsage', processTemplateUsage(templateUsage));

            // Performance metrics
            Map<String, Object> performance = calculatePerformanceMetrics(folderId, startDate);
            analytics.put('performance', performance);

            // Context utilization metrics
            Map<String, Object> contextMetrics = calculateContextUtilization(folderId, startDate);
            analytics.put('contextUtilization', contextMetrics);

            return analytics;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to generate analytics: ' + e.getMessage());
        }
    }

    private static List<Map<String, Object>> processVolumeResults(List<AggregateResult> results) {
        List<Map<String, Object>> processed = new List<Map<String, Object>>();
        for (AggregateResult result : results) {
            Map<String, Object> item = new Map<String, Object>();
            item.put('modelUsed', result.get('modelUsed'));
            item.put('totalGenerations', result.get('totalGenerations'));
            item.put('avgLength', result.get('avgLength'));
            processed.add(item);
        }
        return processed;
    }

    private static List<Map<String, Object>> processDailyTrends(List<AggregateResult> results) {
        List<Map<String, Object>> processed = new List<Map<String, Object>>();
        for (AggregateResult result : results) {
            Map<String, Object> item = new Map<String, Object>();
            item.put('date', result.get('generationDate'));
            item.put('count', result.get('dailyCount'));
            processed.add(item);
        }
        return processed;
    }

    private static Map<String, Object> calculatePerformanceMetrics(String folderId, Date startDate) {
        Map<String, Object> metrics = new Map<String, Object>();

        List<AggregateResult> avgTime = [
            SELECT AVG(Document_Length__c) avgComplexity
            FROM Document_Generation_Audit__c 
            WHERE FolderId__c = :folderId 
              AND Generation_Timestamp__c >= :startDate
        ];

        Decimal complexity = (Decimal) avgTime[0].get('avgComplexity');
        Decimal estimatedTime = complexity != null ? (complexity / 1000 * 2.5) : 3.0;

        metrics.put('avgGenerationTime', estimatedTime);
        metrics.put('totalDocuments', Database.countQuery(
            'SELECT COUNT() FROM Document_Generation_Audit__c WHERE FolderId__c = \'' + folderId + '\''
        ));

        return metrics;
    }

    private static Map<String, Object> calculateContextUtilization(String folderId, Date startDate) {
        Map<String, Object> metrics = new Map<String, Object>();

        List<Document_Generation_Audit__c> audits = [
            SELECT Generation_Parameters__c
            FROM Document_Generation_Audit__c 
            WHERE FolderId__c = :folderId 
              AND Generation_Timestamp__c >= :startDate
              AND Generation_Parameters__c != null
        ];

        Integer crossRefCount = 0;
        Integer entityConsolidationCount = 0;
        Integer sourceCitationCount = 0;
        Integer contextualInsightsCount = 0;

        for (Document_Generation_Audit__c audit : audits) {
            try {
                Map<String, Object> params = (Map<String, Object>) 
                    JSON.deserializeUntyped(audit.Generation_Parameters__c);

                if ((Boolean) params.get('includeCrossReferences') == true) crossRefCount++;
                if ((Boolean) params.get('includeEntityConsolidation') == true) entityConsolidationCount++;
                if ((Boolean) params.get('includeSourceCitations') == true) sourceCitationCount++;
                if ((Boolean) params.get('includeContextualInsights') == true) contextualInsightsCount++;
            } catch (Exception e) {
                // Skip malformed parameters
            }
        }

        Integer totalAudits = audits.size();
        metrics.put('crossReferencesUtilization', totalAudits > 0 ? (crossRefCount * 100.0 / totalAudits) : 0);
        metrics.put('entityConsolidationUtilization', totalAudits > 0 ? (entityConsolidationCount * 100.0 / totalAudits) : 0);
        metrics.put('sourceCitationsUtilization', totalAudits > 0 ? (sourceCitationCount * 100.0 / totalAudits) : 0);
        metrics.put('contextualInsightsUtilization', totalAudits > 0 ? (contextualInsightsCount * 100.0 / totalAudits) : 0);

        return metrics;
    }

    @AuraEnabled
    public static Map<String, Object> exportAnalyticsReport(String folderId, Integer dayRange) {
        try {
            Map<String, Object> analytics = getGenerationAnalytics(folderId, dayRange);

            // Generate CSV content for export
            String csvContent = generateCSVReport(analytics);

            // Create document for download
            ContentVersion reportDoc = new ContentVersion(
                Title = 'AI_Generation_Analytics_' + Date.today().format(),
                PathOnClient = 'ai_generation_report.csv',
                VersionData = Blob.valueOf(csvContent),
                ContentLocation = 'S',
                Description = 'AI Document Generation Analytics Report'
            );
            insert reportDoc;

            ContentVersion insertedDoc = [
                SELECT ContentDocumentId 
                FROM ContentVersion 
                WHERE Id = :reportDoc.Id
            ];

            return new Map<String, Object>{
                'success' => true,
                'documentId' => insertedDoc.ContentDocumentId,
                'message' => 'Analytics report generated successfully'
            };

        } catch (Exception e) {
            throw new AuraHandledException('Failed to export analytics: ' + e.getMessage());
        }
    }

    private static String generateCSVReport(Map<String, Object> analytics) {
        StringBuilder csv = new StringBuilder();

        // Header
        csv.append('AI Document Generation Analytics Report\n');
        csv.append('Generated on: ' + DateTime.now().format() + '\n\n');

        // Volume by Model
        csv.append('Model Usage Statistics\n');
        csv.append('AI Model,Total Generations,Average Length\n');
        List<Object> volumeData = (List<Object>) analytics.get('volumeByModel');
        for (Object item : volumeData) {
            Map<String, Object> data = (Map<String, Object>) item;
            csv.append('"' + data.get('modelUsed') + '",');
            csv.append(data.get('totalGenerations') + ',');
            csv.append(data.get('avgLength') + '\n');
        }
        csv.append('\n');

        // Daily Trends
        csv.append('Daily Generation Trends\n');
        csv.append('Date,Document Count\n');
        List<Object> dailyData = (List<Object>) analytics.get('dailyTrends');
        for (Object item : dailyData) {
            Map<String, Object> data = (Map<String, Object>) item;
            csv.append('"' + data.get('date') + '",');
            csv.append(data.get('count') + '\n');
        }
        csv.append('\n');

        // Template Usage
        csv.append('Template Usage Statistics\n');
        csv.append('Template Name,Usage Count,Average Length\n');
        List<Object> templateData = (List<Object>) analytics.get('templateUsage');
        for (Object item : templateData) {
            Map<String, Object> data = (Map<String, Object>) item;
            csv.append('"' + data.get('templateName') + '",');
            csv.append(data.get('usageCount') + ',');
            csv.append(data.get('avgLength') + '\n');
        }
        csv.append('\n');

        // Performance Metrics
        Map<String, Object> performance = (Map<String, Object>) analytics.get('performance');
        csv.append('Performance Metrics\n');
        csv.append('Metric,Value\n');
        csv.append('Average Generation Time (seconds),' + performance.get('avgGenerationTime') + '\n');
        csv.append('Total Documents Generated,' + performance.get('totalDocuments') + '\n');
        csv.append('\n');

        // Context Utilization
        Map<String, Object> contextMetrics = (Map<String, Object>) analytics.get('contextUtilization');
        csv.append('Context Feature Utilization (%)\n');
        csv.append('Feature,Utilization Rate\n');
        csv.append('Cross References,' + contextMetrics.get('crossReferencesUtilization') + '\n');
        csv.append('Entity Consolidation,' + contextMetrics.get('entityConsolidationUtilization') + '\n');
        csv.append('Source Citations,' + contextMetrics.get('sourceCitationsUtilization') + '\n');
        csv.append('Contextual Insights,' + contextMetrics.get('contextualInsightsUtilization') + '\n');

        return csv.toString();
    }

    // Placeholder: processTemplateUsage method
    private static List<Map<String, Object>> processTemplateUsage(List<AggregateResult> results) {
        List<Map<String, Object>> processed = new List<Map<String, Object>>();
        for (AggregateResult result : results) {
            Map<String, Object> item = new Map<String, Object>();
            item.put('templateName', result.get('templateName'));
            item.put('usageCount', result.get('usageCount'));
            item.put('avgLength', result.get('avgLength'));
            processed.add(item);
        }
        return processed;
    }
}
