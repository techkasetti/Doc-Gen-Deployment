@IsTest
private class DocumentUnlockServiceTest {
    @IsTest static void testUnlockDocument_null() {
        Test.startTest();
        Boolean ok = DocumentUnlockService.unlockDocument(null, null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}