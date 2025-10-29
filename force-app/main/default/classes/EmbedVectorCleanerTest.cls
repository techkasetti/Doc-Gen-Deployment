@IsTest
private class EmbedVectorCleanerTest {
    @IsTest static void testPruneOldEmbeddings() {
        Test.startTest();
        Integer c = EmbedVectorCleaner.pruneOldEmbeddings(365);
        Test.stopTest();
        System.assertEquals(0, c);
    }
}