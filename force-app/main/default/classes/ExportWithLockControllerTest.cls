@IsTest
private class ExportWithLockControllerTest {
    @IsTest static void testExportWithLock() {
        Test.startTest();
        Boolean ok = ExportWithLockController.exportWithLock('lk1');
        Test.stopTest();
        System.assertEquals(true, ok);
    }
}
