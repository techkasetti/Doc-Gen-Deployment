@IsTest
private class DocumentRestoreServiceTest {
    @IsTest static void testRestoreNull() {
        Test.startTest();
        Boolean ok = DocumentRestoreService.restoreDocument(null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}