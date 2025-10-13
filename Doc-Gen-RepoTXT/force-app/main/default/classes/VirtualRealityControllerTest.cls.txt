@isTest
private class VirtualRealityControllerTest {
    @isTest static void testGetVRSession() {
        Test.startTest();
        Map<String,Object> r = VirtualRealityController.getVRSession('s1');
        Test.stopTest();
        System.assertEquals('active', r.get('status'));
    }
}
