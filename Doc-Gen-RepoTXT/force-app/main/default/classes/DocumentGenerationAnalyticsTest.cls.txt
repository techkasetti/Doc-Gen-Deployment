@IsTest
public class DocumentGenerationAnalyticsTest {

    // ------------------------------------------------
    // Test Data Setup
    // ------------------------------------------------
    @TestSetup
    static void setupTestData() {
        createTestDocuments();
        createTestSignatureRequests();
        createTestAnalyticsData();
        createTestComplianceRecords();
    }

    // ------------------------------------------------
    // Test Methods
    // ------------------------------------------------
    @IsTest
    static void testGetDocumentMetrics() {
        Test.startTest();
        Map<String, Object> result = DocumentGenerationAnalytics.getDocumentMetrics('Last30Days');
        System.assertNotEquals(null, result, 'Document metrics should not be null');
        Test.stopTest();
    }

    @IsTest
    static void testGetUserAnalytics() {
        Test.startTest();
        Map<String, Object> result = DocumentGenerationAnalytics.getUserAnalytics('Last7Days');
        System.assert(result.containsKey('ActiveUsers'), 'User metrics should include ActiveUsers');
        Test.stopTest();
    }

    @IsTest
    static void testGetSystemPerformance() {
        Test.startTest();
        Map<String, Object> result = DocumentGenerationAnalytics.getSystemPerformance();
        System.assert(result.containsKey('SystemStatus'), 'System metrics should include SystemStatus');
        Test.stopTest();
    }

    @IsTest
    static void testGetComplianceMetrics() {
        Test.startTest();
        Map<String, Object> result = DocumentGenerationAnalytics.getComplianceMetrics('LastQuarter');
        System.assert(result.containsKey('ComplianceScore'), 'Compliance metrics should include ComplianceScore');
        Test.stopTest();
    }

    @IsTest
    static void testExportToExternalPlatforms() {
        Test.startTest();
        Boolean success = DocumentGenerationAnalytics.exportToExternalPlatforms('ExternalSystem1');
        System.assertEquals(true, success, 'Export should return true on success');
        Test.stopTest();
    }

    @IsTest
    static void testGenerateComplianceReport() {
        Test.startTest();
        String reportId = DocumentGenerationAnalytics.generateComplianceReport('Annual');
        System.assertNotEquals(null, reportId, 'Compliance report ID should not be null');
        Test.stopTest();
    }

    @IsTest
    static void testExportAnalyticsToCSV() {
        Test.startTest();
        String csvContent = DocumentGenerationAnalytics.exportAnalyticsToCSV();
        System.assert(csvContent.contains(','), 'CSV export should contain commas');
        Test.stopTest();
    }

    @IsTest
    static void testScheduleRecurringReport() {
        Test.startTest();
        Boolean scheduled = DocumentGenerationAnalytics.scheduleRecurringReport('Weekly');
        System.assertEquals(true, scheduled, 'Recurring report should be scheduled');
        Test.stopTest();
    }

    @IsTest
    static void testGetSystemHealthMetrics() {
        Test.startTest();
        Map<String, Object> health = DocumentGenerationAnalytics.getSystemHealthMetrics();
        System.assert(health.containsKey('LastChecked'), 'Health metrics should include LastChecked');
        Test.stopTest();
    }

    @IsTest
    static void testGetUserBehaviorAnalytics() {
        Test.startTest();
        Map<String, Object> behavior = DocumentGenerationAnalytics.getUserBehaviorAnalytics('005XXXXXXXXXXXX');
        System.assert(behavior.containsKey('AverageActivityPerDay'), 'User behavior analytics should return activity data');
        Test.stopTest();
    }

    @IsTest
    static void testGetPredictiveInsights() {
        Test.startTest();
        Map<String, Object> insights = DocumentGenerationAnalytics.getPredictiveInsights('LastMonth');
        System.assert(insights.containsKey('TrendDirection'), 'Predictive insights should include TrendDirection');
        Test.stopTest();
    }

    @IsTest
    static void testErrorHandling() {
        Test.startTest();
        try {
            DocumentGenerationAnalytics.getDocumentMetrics(null);
            System.assert(false, 'Exception should have been thrown for null input');
        } catch (Exception e) {
            System.assert(true, 'Expected exception caught');
        }
        Test.stopTest();
    }

    @IsTest
    static void testBulkOperations() {
        Test.startTest();
        Boolean processed = DocumentGenerationAnalytics.processBulkAnalytics(new List<Id>{
            '001XXXXXXXXXXXX', '001YYYYYYYYYYYY'
        });
        System.assertEquals(true, processed, 'Bulk operation should succeed');
        Test.stopTest();
    }

    @IsTest
    static void testSecurityValidation() {
        Test.startTest();
        Boolean isValid = DocumentGenerationAnalytics.validateSecurityContext(UserInfo.getUserId());
        System.assertEquals(true, isValid, 'Security validation should pass for valid user');
        Test.stopTest();
    }

    // ------------------------------------------------
    // Private Helper Methods (Test Data Creation)
    // ------------------------------------------------
    private static void createTestDocuments() {
        List<Document> docs = new List<Document>();
        for (Integer i = 0; i < 5; i++) {
            docs.add(new Document(
                Name = 'Test Document ' + i,
                FolderId = UserInfo.getUserId()
            ));
        }
        insert docs;
    }

    private static void createTestSignatureRequests() {
        List<Signature_Request__c> requests = new List<Signature_Request__c>();
        for (Integer i = 0; i < 5; i++) {
            requests.add(new Signature_Request__c(
                Name = 'Request ' + i,
                Status__c = 'Pending'
            ));
        }
        insert requests;
    }

    private static void createTestAnalyticsData() {
        List<Analytics_Record__c> records = new List<Analytics_Record__c>();
        for (Integer i = 0; i < 3; i++) {
            records.add(new Analytics_Record__c(
                Metric_Name__c = 'Metric ' + i,
                Metric_Value__c = i * 10
            ));
        }
        insert records;
    }

    private static void createTestComplianceRecords() {
        List<Compliance_Record__c> records = new List<Compliance_Record__c>();
        for (Integer i = 0; i < 2; i++) {
            records.add(new Compliance_Record__c(
                Name = 'Compliance Record ' + i,
                Status__c = 'Valid'
            ));
        }
        insert records;
    }
}
