@IsTest
private class IoTControllerTest {
    @IsTest static void testRegisterDeviceEvent_invalid() {
        Test.startTest();
        Map<String,Object> r = IoTController.registerDeviceEvent('', null);
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
