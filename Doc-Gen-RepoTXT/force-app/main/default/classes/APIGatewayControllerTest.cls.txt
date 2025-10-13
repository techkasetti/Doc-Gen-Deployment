@isTest
private class APIGatewayControllerTest {
    @isTest static void testProxy() {
        Test.startTest();
        Map<String,Object> r = APIGatewayController.proxy('/health', 'GET', null);
        Test.stopTest();
        System.assertEquals('proxied', r.get('status'));
    }
}
