@IsTest
private class MixedRealityControllerTest {
    @IsTest static void testGetExperienceConfig_invalid() {
        Test.startTest();
        Map<String,Object> r = MixedRealityController.getExperienceConfig('');
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
