@IsTest
private class NotificationSubscriptionServiceTest {
    @IsTest static void testSubscribe_invalid() {
        Test.startTest();
        Boolean ok = NotificationSubscriptionService.subscribeUserToNotifications(null, null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
