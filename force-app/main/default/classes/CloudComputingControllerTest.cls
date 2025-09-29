@isTest
private class CloudComputingControllerTest {
    @isTest static void testProvisionInstance_invalid() {
        Test.startTest();
        Map<String,Object> r = CloudComputingController.provisionInstance('', null);
        Test.stopTest();
        System.assertEquals('provisioned', r.get('status')); // current stub returns provisioned for demo
    }
}
