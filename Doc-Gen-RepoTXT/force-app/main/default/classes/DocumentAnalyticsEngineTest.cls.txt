@IsTest
private class DocumentAnalyticsEngineTest {
    @IsTest static void testComputeDocumentMetrics() {
        Test.startTest();
        Map<String,Object> m = DocumentAnalyticsEngine.computeDocumentMetrics(null);
        Test.stopTest();
        System.assert(m.containsKey('views'));
    }
}