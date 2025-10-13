@IsTest
private class IntegrationHealthControllerTest {
    @IsTest static void testHealthCheck() {
        Test.startTest();
        Map<String,Object> h = IntegrationHealthController.healthCheck();
        Test.stopTest();
        System.assertEquals(true, h.get('ok'));
    }
}
