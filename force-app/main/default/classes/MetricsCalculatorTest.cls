@IsTest
private class MetricsCalculatorTest {
    @IsTest static void testCalculateUsageMetrics_default() {
        Test.startTest();
        Map<String,Decimal> m = MetricsCalculator.calculateUsageMetrics(null, 7);
        Test.stopTest();
        System.assertEquals(0, m.get('total'));
    }
}
