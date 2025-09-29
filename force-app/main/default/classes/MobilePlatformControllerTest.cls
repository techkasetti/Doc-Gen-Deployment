@IsTest
private class MobilePlatformControllerTest {
    @IsTest static void testListSupportedPlatforms() {
        Test.startTest();
        Map<String,Object> r = MobilePlatformController.listSupportedPlatforms();
        Test.stopTest();
        System.assertEquals(true, r.get('ok'));
    }
}
