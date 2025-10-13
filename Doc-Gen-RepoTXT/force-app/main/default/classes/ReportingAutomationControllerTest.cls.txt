@IsTest
private class ReportingAutomationControllerTest {
    @IsTest static void testScheduleReport_invalid() {
        Test.startTest();
        Map<String,Object> r = ReportingAutomationController.scheduleReport('', '');
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
