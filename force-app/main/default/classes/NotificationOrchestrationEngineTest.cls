@IsTest
private class NotificationOrchestrationEngineTest {
    @IsTest static void testOrchestrate_invalid() {
        Test.startTest();
        Boolean ok = NotificationOrchestrationEngine.orchestrate(null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
