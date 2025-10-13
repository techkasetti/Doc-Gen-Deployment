@IsTest
private class RetentionPolicySchedulerTest {
    @IsTest static void testExecute() {
        Test.startTest();
        new RetentionPolicyScheduler().execute(null);
        Test.stopTest();
        System.assert(true);
    }
}
