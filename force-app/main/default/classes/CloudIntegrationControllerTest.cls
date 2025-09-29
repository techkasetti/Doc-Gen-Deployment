@isTest
private class CloudIntegrationControllerTest {
    @isTest static void testSyncStorage_invalid() {
        Test.startTest();
        Map<String,Object> r = CloudIntegrationController.syncStorage('');
        Test.stopTest();
        System.assertEquals('error', r.get('status'));
    }
}
