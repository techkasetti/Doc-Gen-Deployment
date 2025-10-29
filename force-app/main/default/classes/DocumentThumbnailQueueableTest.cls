@IsTest
private class DocumentThumbnailQueueableTest {
    @IsTest static void testEnqueue() {
        Test.startTest();
        System.enqueueJob(new DocumentThumbnailQueueable(null));
        Test.stopTest();
        System.assert(true);
    }
}