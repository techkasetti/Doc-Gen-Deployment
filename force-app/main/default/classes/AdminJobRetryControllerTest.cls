@IsTest
private class AdminJobRetryControllerTest {
    @IsTest static void testRetryJob_null() {
        Test.startTest();
        Boolean ok = AdminJobRetryController.retryJob(null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}