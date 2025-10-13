@isTest
private class AutomatedTestingEngineTest {
    @isTest static void testRunTestSuite_invalid() {
        Test.startTest();
        Map<String,Object> r = AutomatedTestingEngine.runTestSuite('');
        Test.stopTest();
        System.assertEquals('error', r.get('status'));
    }
}
