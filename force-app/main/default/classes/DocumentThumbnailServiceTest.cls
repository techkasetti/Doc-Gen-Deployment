@IsTest
private class DocumentThumbnailServiceTest {
    @IsTest static void testGenerateThumbnail_null() {
        Test.startTest();
        Id id = DocumentThumbnailService.generateThumbnail(null);
        Test.stopTest();
        System.assertEquals(null, id);
    }
}