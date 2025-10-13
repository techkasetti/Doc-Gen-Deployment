// =====================================
// AnalyticsController.cls
// =====================================
public with sharing class AnalyticsController {

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
        PageReference pdfPage = Page.AnalyticsReportPDF;
        pdfPage.getParameters().put('data', JSON.serialize(analyticsData));
        
        Blob pdfBlob;
        if (Test.isRunningTest()) {
            pdfBlob = Blob.valueOf('Test PDF Content');
        } else {
            pdfBlob = pdfPage.getContentAsPDF();
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
        StringBuilder csvContent = new StringBuilder();
        
        // Header
        csvContent.append('Metric,Value,Timestamp\n');
        
        // Add metrics
        csvContent.append('Total Requests,' + analyticsData.get('totalRequests') + ',' + DateTime.now() + '\n');
        csvContent.append('Completion Rate,' + analyticsData.get('completionRate') + '%,' + DateTime.now() + '\n');
        csvContent.append('Average Completion Time,' + analyticsData.get('averageCompletionTime') + ' hours,' + DateTime.now() + '\n');
        csvContent.append('Active Users,' + analyticsData.get('activeUsers') + ',' + DateTime.now() + '\n');
        csvContent.append('System Uptime,' + analyticsData.get('systemUptime') + '%,' + DateTime.now() + '\n');
        csvContent.append('Performance Score,' + analyticsData.get('performanceScore') + ',' + DateTime.now() + '\n');
        
        // Create CSV file
        ContentVersion cv = new ContentVersion();
        cv.Title = 'E-Signature Analytics Report - ' + DateTime.now().format();
        cv.PathOnClient = 'analytics-report.csv';
        cv.VersionData = Blob.valueOf(csvContent.toString());
        cv.IsMajorVersion = true;
        insert cv;
        
        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE Id = :cv.ContentDocumentId LIMIT 1];
        return cd.Id;
    }

    // Stub methods for completeness
    private static Map<String, Object> getAdvancedAnalytics(String period, Boolean detailed) {
        Map<String, Object> data = new Map<String, Object>();
        data.put('totalRequests', 120);
        data.put('completionRate', 95);
        data.put('averageCompletionTime', 2.5);
        data.put('activeUsers', 50);
        data.put('systemUptime', 99.9);
        data.put('performanceScore', 87);
        return data;
    }

    private static void logAnalyticsError(Exception e, String methodName) {
        System.debug('Error in ' + methodName + ': ' + e.getMessage());
    }
}

