@isTest
private class AnalyticsEngineControllerTest {
    @isTest static void testRunDashboardRefresh_invalid() {
        Test.startTest();
        Map<String,Object> r = AnalyticsEngineController.runDashboardRefresh('');
        Test.stopTest();
        System.assertEquals('error', r.get('status'));
    }
}
