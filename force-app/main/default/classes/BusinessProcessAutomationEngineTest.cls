@isTest
private class BusinessProcessAutomationEngineTest {
    @isTest static void testRunAutomation_invalid() {
        Test.startTest();
        Map<String,Object> r = BusinessProcessAutomationEngine.runAutomation('', null);
        Test.stopTest();
        System.assertEquals('error', r.get('status'));
    }
    @isTest static void testRunAutomation_ok() {
        Test.startTest();
        Map<String,Object> r = BusinessProcessAutomationEngine.runAutomation('proc1', null);
        Test.stopTest();
        System.assertEquals('completed', r.get('status'));
    }
}