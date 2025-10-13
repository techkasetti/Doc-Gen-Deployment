@IsTest
private class ExportFinalizeControllerTest {
    @IsTest static void testFinalizeNull() {
        Test.startTest();
        Boolean ok = ExportFinalizeController.finalizeExport(null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
