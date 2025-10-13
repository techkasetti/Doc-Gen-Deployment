@IsTest
private class ExportIntegrityControllerTest {
    @IsTest static void testVerifyExport_null() {
        Test.startTest();
        Map<String,Object> r = ExportIntegrityController.verifyExport(null);
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
