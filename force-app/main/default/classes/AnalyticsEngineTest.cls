@isTest
private class AnalyticsEngineTest {
    @isTest static void testComputeAnalytics_missing() {
        Test.startTest();
        Map<String,Object> r = AnalyticsEngine.computeAnalytics('', null);
        Test.stopTest();
        System.assert(r.containsKey('error'));
    }
}