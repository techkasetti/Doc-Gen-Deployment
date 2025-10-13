@IsTest
private class MobileOptimizationControllerTest {
    @IsTest static void testRecommendOptimizations_invalid() {
        Test.startTest();
        Map<String,Object> r = MobileOptimizationController.recommendOptimizations('');
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
