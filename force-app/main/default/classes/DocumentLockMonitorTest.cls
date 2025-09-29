@IsTest
private class DocumentLockMonitorTest {
    @IsTest static void testExecute_noThrow() {
        Test.startTest();
        new DocumentLockMonitor().execute(null);
        Test.stopTest();
        System.assert(true);
    }
}
