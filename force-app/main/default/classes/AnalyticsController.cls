// =====================================
// AnalyticsController.txt
// =====================================
// =====================================
// AnalyticsController.txt
// =====================================
public with sharing class AnalyticsController {
    /**
     * Returns basic analytics data for the UI.
     */
    @AuraEnabled
    public static Map<String, Object> getAnalyticsData() {
        return getAdvancedAnalytics('last_30_days', false);
    }

    /**
     * Returns advanced analytics data for a given period and detail level.
     */
    @AuraEnabled
    public static Map<String, Object> getAdvancedAnalytics(String period, Boolean detailed) {
        Map<String, Object> data = new Map<String, Object>();
        // Example stubbed data, can be replaced with real queries
        data.put('totalRequests', 120);
        data.put('completionRate', 95);
        data.put('averageCompletionTime', 2.5);
        data.put('activeUsers', 50);
        data.put('systemUptime', 99.9);
        data.put('performanceScore', 87);
        if (detailed) {
            data.put('detailedBreakdown', 'Detailed analytics breakdown goes here.');
        }
        return data;
    }

    /**
     * Returns recent activity for analytics (stubbed for demo).
     */
    @AuraEnabled
    public static List<Map<String, Object>> getRecentActivity() {
        List<Map<String, Object>> activities = new List<Map<String, Object>>();
        activities.add(new Map<String, Object>{'timestamp'=>String.valueOf(DateTime.now()),'action'=>'Export','user'=>'User A'});
        activities.add(new Map<String, Object>{'timestamp'=>String.valueOf(DateTime.now().addMinutes(-10)),'action'=>'View','user'=>'User B'});
        activities.add(new Map<String, Object>{'timestamp'=>String.valueOf(DateTime.now().addMinutes(-30)),'action'=>'Download','user'=>'User C'});
        return activities;
    }

    @TestVisible
    private static Boolean mockAccessCheck = null;

    // Export functionality for reports
    @AuraEnabled
    public static String exportAnalyticsData(String format) {
        try {
            if (!validateAnalyticsAccess()) {
                throw new AuraHandledException('Insufficient permissions for analytics export');
            }
            
            Map<String, Object> analyticsData = getAdvancedAnalytics('last_30_days', true);
            
            if (format == 'PDF') {
                return generatePDFReport(analyticsData);
            } else if (format == 'CSV') {
                return generateCSVReport(analyticsData);
            } else {
                throw new AuraHandledException('Unsupported export format: ' + format);
            }
        } catch (Exception e) {
            logAnalyticsError(e, 'exportAnalyticsData');
            throw new AuraHandledException('Export failed: ' + e.getMessage());
        }
    }

    private static Boolean validateAnalyticsAccess() {
        if (mockAccessCheck != null) {
            return mockAccessCheck;
        }
        // Original validation logic (stubbed for now)
        return true;
    }

    private static String generatePDFReport(Map<String, Object> analyticsData) {
        // Generate PDF content using PageReference or external PDF service
        // Use a string-based PageReference so the class doesn't depend on
        // a compile-time Page token which may be missing in some orgs.
        PageReference pdfPage = new PageReference('/apex/AnalyticsReportPDF');
        pdfPage.getParameters().put('data', JSON.serialize(analyticsData));

        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Test PDF Content');
        } else {
            // Surround getContentAsPDF with a try/catch to handle runtime issues
            // when the Visualforce page is not present or rendering fails.
            try {
                pdfBlob = pdfPage.getContentAsPDF();
            } catch (Exception ex) {
                // Fall back to a placeholder PDF-like blob so export still returns a ContentDocument
                System.debug('PDF generation failed: ' + ex.getMessage());
                pdfBlob = Blob.valueOf('Fallback PDF Content');
            }
        }
        
        // Create document record for download
        ContentVersion cv = new ContentVersion();
        cv.Title = 'E-Signature Analytics Report - ' + DateTime.now().format();
        cv.PathOnClient = 'analytics-report.pdf';
        cv.VersionData = pdfBlob;
        cv.IsMajorVersion = true;
        insert cv;
        
        // Get content document ID for sharing
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId LIMIT 1];
        
        return cd.Id;
    }

    private static String generateCSVReport(Map<String, Object> analyticsData) {
        String csvContent = '';

        // Header
        csvContent += 'Metric,Value,Timestamp\n';

        // Add metrics
        csvContent += 'Total Requests,' + String.valueOf(analyticsData.get('totalRequests')) + ',' + String.valueOf(DateTime.now()) + '\n';
        csvContent += 'Completion Rate,' + String.valueOf(analyticsData.get('completionRate')) + '%,' + String.valueOf(DateTime.now()) + '\n';
        csvContent += 'Average Completion Time,' + String.valueOf(analyticsData.get('averageCompletionTime')) + ' hours,' + String.valueOf(DateTime.now()) + '\n';
        csvContent += 'Active Users,' + String.valueOf(analyticsData.get('activeUsers')) + ',' + String.valueOf(DateTime.now()) + '\n';
        csvContent += 'System Uptime,' + String.valueOf(analyticsData.get('systemUptime')) + '%,' + String.valueOf(DateTime.now()) + '\n';
        csvContent += 'Performance Score,' + String.valueOf(analyticsData.get('performanceScore')) + ',' + String.valueOf(DateTime.now()) + '\n';

        // Create CSV file
        ContentVersion cv = new ContentVersion();
        cv.Title = 'E-Signature Analytics Report - ' + DateTime.now().format();
        cv.PathOnClient = 'analytics-report.csv';
        cv.VersionData = Blob.valueOf(csvContent);
        cv.IsMajorVersion = true;
        insert cv;

        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId LIMIT 1];
        return cd.Id;
    }

    
    private static void logAnalyticsError(Exception e, String methodName) {
        System.debug('Error in ' + methodName + ': ' + e.getMessage());
    }
}