@IsTest
private class KubernetesControllerTest {
    @IsTest static void testDeployManifest_invalid() {
        Test.startTest();
        Map<String,Object> r = KubernetesController.deployManifest('');
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
