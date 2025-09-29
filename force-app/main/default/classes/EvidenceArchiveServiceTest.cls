@IsTest
private class EvidenceArchiveServiceTest {
    @IsTest static void testArchiveBundle_null() {
        Test.startTest();
        Boolean ok = EvidenceArchiveService.archiveBundle(null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
