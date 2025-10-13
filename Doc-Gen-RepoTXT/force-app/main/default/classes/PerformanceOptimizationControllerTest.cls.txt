@IsTest
private class PerformanceOptimizationControllerTest {
    @IsTest static void testApplyOptimization_invalid() {
        Test.startTest();
        Boolean ok = PerformanceOptimizationController.applyOptimization('');
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
