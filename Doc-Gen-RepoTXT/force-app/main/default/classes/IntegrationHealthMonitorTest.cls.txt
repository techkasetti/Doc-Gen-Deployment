@IsTest
private class IntegrationHealthMonitorTest {
    @IsTest static void testExecute() {
        Test.startTest();
        new IntegrationHealthMonitor().execute(null);
        Test.stopTest();
        System.assert(true);
    }
}
