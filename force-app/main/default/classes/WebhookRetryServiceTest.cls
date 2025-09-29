@IsTest
private class WebhookRetryServiceTest {
    @IsTest static void testRecordRetry_invalid() {
        Test.startTest();
        Boolean ok = WebhookRetryService.recordRetry(null, null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
