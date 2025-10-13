@isTest
private class ContainerOrchestrationControllerTest {
    @isTest static void testGetClusterStatus() {
        Test.startTest();
        Map<String,Object> r = ContainerOrchestrationController.getClusterStatus('clusterA');
        Test.stopTest();
        System.assertEquals('healthy', r.get('status'));
    }
}
