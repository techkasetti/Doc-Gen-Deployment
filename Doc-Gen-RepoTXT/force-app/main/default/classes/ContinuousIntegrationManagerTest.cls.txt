@isTest
private class ContinuousIntegrationManagerTest {
    @isTest static void testTriggerPipeline_invalid() {
        Test.startTest();
        Map<String,Object> r = ContinuousIntegrationManager.triggerPipeline('', null);
        Test.stopTest();
        System.assertEquals('error', r.get('status'));
    }
    @isTest static void testTriggerPipeline_ok() {
        Test.startTest();
        Map<String,Object> r = ContinuousIntegrationManager.triggerPipeline('ci-main', null);
        Test.stopTest();
        System.assertEquals('triggered', r.get('status'));
        System.assert(r.containsKey('runId'));
    }
}
