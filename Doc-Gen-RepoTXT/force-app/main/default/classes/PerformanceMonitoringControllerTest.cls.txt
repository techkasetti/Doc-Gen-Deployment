@IsTest
private class PerformanceMonitoringControllerTest {
    @IsTest static void testGetRecentMetrics_default() {
        Test.startTest();
        Map<String,Object> r = PerformanceMonitoringController.getRecentMetrics(null);
        Test.stopTest();
        System.assertEquals(true, r.get('ok'));
    }
}
