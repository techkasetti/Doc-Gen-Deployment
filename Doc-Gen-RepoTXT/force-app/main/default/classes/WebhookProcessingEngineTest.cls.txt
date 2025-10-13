@IsTest
private class WebhookProcessingEngineTest {
    @IsTest static void testProcessIncoming_invalid() {
        Test.startTest();
        Boolean ok = WebhookProcessingEngine.processIncoming('', '');
        Test.stopTest();
        System.assertEquals(false, ok);
    }

    @IsTest static void testProcessIncoming_ok() {
        Test.startTest();
        Boolean ok = WebhookProcessingEngine.processIncoming('sig', '{"k":"v"}');
        Test.stopTest();
        System.assertEquals(true, ok);
    }
}
