@IsTest
private class MiddlewareControllerTest {
    @IsTest static void testProxyToMiddleware_invalid() {
        Test.startTest();
        Map<String,Object> r = MiddlewareController.proxyToMiddleware('', null);
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
