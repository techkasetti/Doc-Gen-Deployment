@IsTest
private class ExportRetentionServiceTest {
    @IsTest static void testEvaluateRetention_empty() {
        Test.startTest();
        Map<String,Object> r = ExportRetentionService.evaluateRetention(365);
        Test.stopTest();
        System.assert(r.containsKey('candidates'));
    }
}
