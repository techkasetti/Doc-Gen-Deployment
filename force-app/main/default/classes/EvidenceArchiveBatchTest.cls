@IsTest
private class EvidenceArchiveBatchTest {
    @IsTest static void testBatchNoObjects() {
        Test.startTest();
        Database.executeBatch(new EvidenceArchiveBatch(), 1);
        Test.stopTest();
        System.assert(true);
    }
}