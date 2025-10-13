@IsTest
private class QuantumOptimizationControllerTest {
    @IsTest static void testOptimizeProblem_invalid() {
        Test.startTest();
        Map<String,Object> r = QuantumOptimizationController.optimizeProblem('');
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
