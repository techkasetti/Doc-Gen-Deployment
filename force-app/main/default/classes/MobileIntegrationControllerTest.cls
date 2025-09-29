@IsTest
private class MobileIntegrationControllerTest {
    @IsTest static void testPushNotificationToken_invalid() {
        Test.startTest();
        Boolean ok = MobileIntegrationController.pushNotificationToken(null, '');
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
