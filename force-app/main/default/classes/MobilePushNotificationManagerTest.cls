@IsTest
private class MobilePushNotificationManagerTest {
    @IsTest static void testSendPush_invalid() {
        Test.startTest();
        Boolean ok = MobilePushNotificationManager.sendPush('', '', '');
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
