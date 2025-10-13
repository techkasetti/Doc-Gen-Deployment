@IsTest
private class ExportMonitorControllerV2Test {
    @IsTest static void testSummary() {
        Test.startTest();
        Map<String,Integer> r = ExportMonitorControllerV2.summary(7);
        Test.stopTest();
        System.assert(r.containsKey('exports'));
    }
}
