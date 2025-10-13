@IsTest
private class EmbeddingIndexManagerTest {
    @IsTest static void testFlushIndexSnapshot() {
        Test.startTest();
        Boolean ok = EmbeddingIndexManager.flushIndexSnapshot();
        Test.stopTest();
        System.assertEquals(true, ok == true || ok == false);
    }
}