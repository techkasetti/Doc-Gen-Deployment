@isTest
private class ContextAwareQueueableAnalyzerTest {
    @isTest static void testEnqueue() {
        Test.startTest();
        Id jobId = ContextAwareQueueableAnalyzer.enqueue('p1');
        Test.stopTest();
        System.assertNotEquals(null, jobId);
    }
}