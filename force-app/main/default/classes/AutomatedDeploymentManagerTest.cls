@isTest
private class AutomatedDeploymentManagerTest {
    @isTest static void testDeployArtifact_invalid() {
        Test.startTest();
        Map<String,Object> r = AutomatedDeploymentManager.deployArtifact('');
        Test.stopTest();
        System.assertEquals('error', r.get('status'));
    }
}