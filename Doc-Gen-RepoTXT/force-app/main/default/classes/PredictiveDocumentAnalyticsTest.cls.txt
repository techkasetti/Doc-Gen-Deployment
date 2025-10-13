@IsTest
private class PredictiveDocumentAnalyticsTest {
    @IsTest static void testAnalyzeDocuments_invalid() {
        Test.startTest();
        Map<String,Object> r = PredictiveDocumentAnalytics.analyzeDocuments(null);
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
