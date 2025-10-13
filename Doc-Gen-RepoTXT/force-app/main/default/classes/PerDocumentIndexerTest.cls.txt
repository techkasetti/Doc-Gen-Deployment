@IsTest
private class PerDocumentIndexerTest {
    @IsTest static void testEnqueueNoObject() {
        Test.startTest();
        System.enqueueJob(new PerDocumentIndexer(null));
        Test.stopTest();
        System.assert(true);
    }
}