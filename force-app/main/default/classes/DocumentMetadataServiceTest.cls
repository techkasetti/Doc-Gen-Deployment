@IsTest
private class DocumentMetadataServiceTest {
    @IsTest static void testGetMetadata_null() {
        Test.startTest();
        Map<String,Object> r = DocumentMetadataService.getMetadata(null);
        Test.stopTest();
        System.assertEquals(false, (Boolean)r.get('ok'));
    }
}