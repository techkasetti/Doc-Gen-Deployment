@isTest
private class DataVisualizationControllerTest {
    @isTest static void testGetChart() {
        Test.startTest();
        Map<String,Object> r = DataVisualizationController.getChart('c1', null);
        Test.stopTest();
        System.assert(r.containsKey('data'));
    }
}
