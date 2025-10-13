@IsTest
private class MicroservicesControllerTest {
    @IsTest static void testCallService_invalid() {
        Test.startTest();
        Map<String,Object> r = MicroservicesController.callService('', '', null);
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
