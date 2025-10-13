@IsTest
private class DataExportAuditControllerTest {
    @IsTest static void testListRecentExports() {
        Test.startTest();
        List<Map<String,Object>> r = DataExportAuditController.listRecentExports(7);
        Test.stopTest();
        System.assertNotEquals(null, r);
    }
}
