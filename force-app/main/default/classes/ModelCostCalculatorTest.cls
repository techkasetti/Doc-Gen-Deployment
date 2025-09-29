@IsTest
private class ModelCostCalculatorTest {
    @IsTest static void testEstimateModelCost() {
        Test.startTest();
        Decimal d = ModelCostCalculator.estimateModelCost('m1', 1000);
        Test.stopTest();
        System.assert(d > 0);
    }
}
