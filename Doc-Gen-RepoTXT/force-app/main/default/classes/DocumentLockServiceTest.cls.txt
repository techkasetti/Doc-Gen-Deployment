@IsTest
private class DocumentLockServiceTest {
    @IsTest static void testLockDocument_null() {
        Test.startTest();
        Boolean ok = DocumentLockService.lockDocument(null, null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
