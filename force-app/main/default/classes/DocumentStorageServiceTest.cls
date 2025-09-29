@IsTest
private class DocumentStorageServiceTest {
    @IsTest static void testStoreBinaryNull() {
        Test.startTest();
        Id id = DocumentStorageService.storeBinary(null, null);
        Test.stopTest();
        System.assertEquals(null, id);
    }
}