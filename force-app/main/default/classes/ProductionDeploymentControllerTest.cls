@IsTest
private class ProductionDeploymentControllerTest {
    @IsTest static void testDeployToProduction_invalid() {
        Test.startTest();
        Map<String,Object> r = ProductionDeploymentController.deployToProduction('');
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
