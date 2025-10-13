@IsTest
private class DocumentMergeServiceTest {
    @IsTest static void testMergeNull() {
        Test.startTest();
        Id id = DocumentMergeService.mergeDocuments(null, null);
        Test.stopTest();
        System.assertEquals(null, id);
    }
}