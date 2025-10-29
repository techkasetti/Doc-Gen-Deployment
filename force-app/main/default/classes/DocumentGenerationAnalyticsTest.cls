@IsTest
public class DocumentGenerationAnalyticsTest {

    // ------------------------------------------------
    // Test Data Setup
    // ------------------------------------------------
    @TestSetup
    static void setupTestData() {
        createTestAnalyticsData();
    }

    // ------------------------------------------------
    // Test Methods
    // ------------------------------------------------
    @IsTest
    static void testGetGenerationAnalytics() {
        Test.startTest();
        Map<String, Object> result = DocumentGenerationAnalytics.getGenerationAnalytics(null, 7);
        System.assertNotEquals(null, result, 'Analytics result should not be null');
        Test.stopTest();
    }

    @IsTest
    static void testExportAnalyticsReport() {
        Test.startTest();
        Map<String, Object> result = DocumentGenerationAnalytics.exportAnalyticsReport(null, 7);
        System.assertEquals(true, result.get('success'), 'Export should be successful');
        Test.stopTest();
    }

    // ------------------------------------------------
    // Private Helper Methods (Test Data Creation)
    // ------------------------------------------------
    private static void createTestAnalyticsData() {
        List<Document_Generation_Audit__c> records = new List<Document_Generation_Audit__c>();
        for (Integer i = 0; i < 3; i++) {
            records.add(new Document_Generation_Audit__c());
        }
        insert records;
    }
}