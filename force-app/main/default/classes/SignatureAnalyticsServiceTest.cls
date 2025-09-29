@IsTest
private class SignatureAnalyticsServiceTest {
    @IsTest static void testComputeSignatureMetrics() {
        Test.startTest();
        Map<String,Integer> m = SignatureAnalyticsService.computeSignatureMetrics(null);
        Test.stopTest();
        System.assert(m.containsKey('totalSignatures'));
    }
}