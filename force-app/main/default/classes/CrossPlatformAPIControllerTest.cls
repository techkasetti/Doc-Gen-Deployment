@isTest
private class CrossPlatformAPIControllerTest {
    @isTest static void testProxy() {
        Test.startTest();
        Map<String,Object> r = CrossPlatformAPIController.proxyCrossPlatform('ios','/health','{}');
        Test.stopTest();
        System.assertEquals('proxied', r.get('status'));
    }
}