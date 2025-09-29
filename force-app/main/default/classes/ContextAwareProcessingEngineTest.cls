@isTest
private class ContextAwareProcessingEngineTest {
    @isTest static void testProcessContext_invalid() {
        Test.startTest();
        ContextAwareProcessingEngine.ContextResult r = ContextAwareProcessingEngine.processContext('', null);
        Test.stopTest();
        System.assertEquals(false, r.ok);
        System.assert(r.details.containsKey('error'));
    }
    @isTest static void testProcessContext_ok() {
        Test.startTest();
        ContextAwareProcessingEngine.ContextResult r = ContextAwareProcessingEngine.processContext('ctx1', new Map<String,Object>{ 'a'=>1 });
        Test.stopTest();
        System.assertEquals(true, r.ok);
        System.assert(Integer.valueOf(r.details.get('receivedKeys').toString()) == 1);
    }
}
