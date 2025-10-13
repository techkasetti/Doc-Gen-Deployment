@IsTest
private class ProgressiveWebAppControllerTest {
    @IsTest static void testGetPwaConfig_invalid() {
        Test.startTest();
        Map<String,Object> r = ProgressiveWebAppController.getPwaConfig('');
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
