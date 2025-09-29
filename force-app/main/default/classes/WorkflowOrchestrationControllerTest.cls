@IsTest
private class WorkflowOrchestrationControllerTest {
    @IsTest static void testStartWorkflow_invalid() {
        Test.startTest();
        Map<String,Object> r = WorkflowOrchestrationController.startWorkflow('', null);
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
