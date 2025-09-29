@IsTest
private class MessageQueueControllerTest {
    @IsTest static void testEnqueueMessage_invalid() {
        Test.startTest();
        Boolean ok = MessageQueueController.enqueueMessage('', null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
