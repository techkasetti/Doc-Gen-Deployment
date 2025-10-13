
// =====================================
// AnalyticsControllerExport_Test.cls
// =====================================
@isTest
private class AnalyticsControllerExportTest {

    @testSetup
    static void setupTestData() {
        // Prepare any required data (if needed in future)
    }

    // Test Export PDF - With Access
    @isTest
    static void testExportAnalyticsDataPDF_WithAccess() {
        AnalyticsController.mockAccessCheck = true;

        Test.startTest();
        String contentDocId = AnalyticsController.exportAnalyticsData('PDF');
        Test.stopTest();

        System.assertNotEquals(null, contentDocId, 'ContentDocument Id should not be null for PDF export');
        System.assertEquals(18, contentDocId.length(), 'Expected a valid Salesforce Id length for ContentDocument');
    }

    // Test Export CSV - With Access
    @isTest
    static void testExportAnalyticsDataCSV_WithAccess() {
        AnalyticsController.mockAccessCheck = true;

        Test.startTest();
        String contentDocId = AnalyticsController.exportAnalyticsData('CSV');
        Test.stopTest();

        System.assertNotEquals(null, contentDocId, 'ContentDocument Id should not be null for CSV export');
        System.assertEquals(18, contentDocId.length(), 'Expected a valid Salesforce Id length for ContentDocument');
    }

    // Test Unsupported Format - With Access
    @isTest
    static void testExportAnalyticsDataUnsupported_WithAccess() {
        AnalyticsController.mockAccessCheck = true;
        Boolean exceptionThrown = false;

        try {
            Test.startTest();
            AnalyticsController.exportAnalyticsData('XML');
            Test.stopTest();
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Unsupported export format'),
                'Expected unsupported format error');
        }

        System.assertEquals(true, exceptionThrown, 'Exception should be thrown for unsupported format');
    }

    // Test Access Denied
    @isTest
    static void testExportAnalyticsData_AccessDenied() {
        AnalyticsController.mockAccessCheck = false;
        Boolean exceptionThrown = false;

        try {
            Test.startTest();
            AnalyticsController.exportAnalyticsData('PDF');
            Test.stopTest();
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Insufficient permissions'),
                'Expected insufficient permissions error');
        }

        System.assertEquals(true, exceptionThrown, 'Export should fail when access is denied');
    }
}
