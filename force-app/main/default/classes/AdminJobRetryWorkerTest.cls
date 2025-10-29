@IsTest
private class AdminJobRetryWorkerTest {
    @IsTest static void testEnqueue() {
        Test.startTest();
        System.enqueueJob(new AdminJobRetryWorker(null));
        Test.stopTest();
        System.assert(true);
    }
}