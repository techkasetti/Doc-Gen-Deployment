@IsTest
private class IndexSnapshotServiceTest {
    @IsTest static void testCreateSnapshot_invalid() {
        Test.startTest();
        Boolean ok = IndexSnapshotService.createSnapshot(null, null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
