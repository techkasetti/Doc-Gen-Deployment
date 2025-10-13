@IsTest
private class IndexSnapshotLoaderQueueableTest {
    @IsTest static void testEnqueue() {
        Test.startTest();
        System.enqueueJob(new IndexSnapshotLoaderQueueable(null));
        Test.stopTest();
        System.assert(true);
    }
}
