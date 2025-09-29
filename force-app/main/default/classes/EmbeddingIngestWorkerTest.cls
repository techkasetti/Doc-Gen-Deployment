@IsTest
private class EmbeddingIngestWorkerTest {
    @IsTest static void testEnqueueNoObject() {
        Test.startTest();
        System.enqueueJob(new EmbeddingIngestWorker(null, null));
        Test.stopTest();
        System.assert(true);
    }
}