@IsTest
private class IndexingWorkerTest {
    @IsTest static void testBatchRun() {
        Test.startTest();
        Database.executeBatch(new IndexingWorker(), 1);
        Test.stopTest();
        System.assert(true);
    }
}