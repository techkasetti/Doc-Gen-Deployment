@IsTest
private class MobileApplicationControllerTest {
    @IsTest static void testGetMobileConfig_invalid() {
        Test.startTest();
        Map<String,Object> r = MobileApplicationController.getMobileConfig('');
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
