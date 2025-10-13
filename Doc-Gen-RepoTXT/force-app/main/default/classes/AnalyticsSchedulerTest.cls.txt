@isTest
private class AnalyticsSchedulerTest {
    @isTest static void testScheduleExecute() {
        Test.startTest();
        (new AnalyticsScheduler()).execute(null);
        Test.stopTest();
        System.assert(true);
    }
}
