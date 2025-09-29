@isTest
private class AdvancedAnalyticsControllerTest {
    @isTest static void testRunAdvancedReport_invalid() {
        Test.startTest();
        Map<String,Object> r = AdvancedAnalyticsController.runAdvancedReport('', null);
        Test.stopTest();
        System.assertEquals('error', r.get('status'));
    }
    @isTest static void testRunAdvancedReport_ok() {
        Test.startTest();
        Map<String,Object> r = AdvancedAnalyticsController.runAdvancedReport('usage_summary', null);
        Test.stopTest();
        System.assertEquals('completed', r.get('status'));
    }
}
