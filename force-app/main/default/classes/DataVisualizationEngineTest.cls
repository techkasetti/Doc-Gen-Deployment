@isTest
private class DataVisualizationEngineTest {
    @isTest static void testRenderDashboardSnapshot_invalid() {
        Test.startTest();
        Boolean ok = DataVisualizationEngine.renderDashboardSnapshot('');
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}