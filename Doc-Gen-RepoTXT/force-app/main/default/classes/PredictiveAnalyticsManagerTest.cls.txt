@IsTest
private class PredictiveAnalyticsManagerTest {
    @IsTest static void testRunPredictionBundle_invalid() {
        Test.startTest();
        Map<String,Object> r = PredictiveAnalyticsManager.runPredictionBundle('');
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
