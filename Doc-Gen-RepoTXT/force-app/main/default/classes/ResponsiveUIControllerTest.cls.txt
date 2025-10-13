@IsTest
private class ResponsiveUIControllerTest {
    @IsTest static void testSetUserPreference_invalid() {
        Test.startTest();
        Boolean ok = ResponsiveUIController.setUserPreference(null, '', '');
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
