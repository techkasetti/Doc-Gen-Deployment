@IsTest
private class UserPersonalizationControllerTest {
    @IsTest static void testGetUserProfileSettings_invalid() {
        Test.startTest();
        Map<String,Object> r = UserPersonalizationController.getUserProfileSettings(null);
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }

    @IsTest static void testSaveUserSetting_invalid() {
        Test.startTest();
        Boolean ok = UserPersonalizationController.saveUserSetting(null, '', '');
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
