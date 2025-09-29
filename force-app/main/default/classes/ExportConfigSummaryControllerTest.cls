@IsTest
private class ExportConfigSummaryControllerTest {
    @IsTest static void testGetSummary() {
        Test.startTest();
        Map<String,Object> r = ExportConfigSummaryController.getSummary();
        Test.stopTest();
        System.assertEquals(true, r.get('ok'));
    }
}
