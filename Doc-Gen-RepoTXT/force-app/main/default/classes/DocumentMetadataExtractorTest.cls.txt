@IsTest
private class DocumentMetadataExtractorTest {
    @IsTest static void testExtractNull() {
        Test.startTest();
        Map<String,String> m = DocumentMetadataExtractor.extractMetadata(null);
        Test.stopTest();
        System.assertEquals(0, m.size());
    }
}