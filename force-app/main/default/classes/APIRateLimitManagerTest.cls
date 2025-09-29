@IsTest
private class APIRateLimitManagerTest {
    @IsTest static void testCheckAndIncrement() {
        Id uid = UserInfo.getUserId();
        Test.startTest();
        Boolean ok1 = APIRateLimitManager.checkAndIncrement(uid, 1);
        Boolean ok2 = APIRateLimitManager.checkAndIncrement(uid, 1);
        Test.stopTest();
        System.assertEquals(true, ok1);
        System.assertEquals(false, ok2);
    }
}