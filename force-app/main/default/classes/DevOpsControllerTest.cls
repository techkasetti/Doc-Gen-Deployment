@isTest
private class DevOpsControllerTest {
    @isTest static void testGetPipelineStatus() {
        Test.startTest();
        Map<String,Object> r = DevOpsController.getPipelineStatus('main-ci');
        Test.stopTest();
        System.assertEquals('healthy', r.get('status'));
    }
    @isTest static void testRestartPipeline_invalid() {
        Test.startTest();
        Boolean ok = DevOpsController.restartPipeline('');
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}