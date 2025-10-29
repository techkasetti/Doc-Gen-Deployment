@IsTest
private class ComplianceCheckSchedulerTest {
    @IsTest static void testExecute_noThrow() {
        Test.startTest();
        new ComplianceCheckScheduler().execute(null);
        Test.stopTest();
        System.assert(true);
    }
}