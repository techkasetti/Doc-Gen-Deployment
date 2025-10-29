@isTest
private class DataScienceControllerTest {
    @isTest static void testRunExperiment() {
        Test.startTest();
        Map<String,Object> r = DataScienceController.runExperiment('exp1', null);
        Test.stopTest();
        System.assertEquals('scheduled', r.get('status'));
    }
}