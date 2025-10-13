@IsTest
private class ReportingEngineControllerTest {
    @IsTest static void testRunReportNow_invalid() {
        Test.startTest();
        Map<String,Object> r = ReportingEngineController.runReportNow('');
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
