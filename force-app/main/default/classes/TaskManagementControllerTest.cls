@IsTest
private class TaskManagementControllerTest {
    @IsTest static void testCreateTask_invalid() {
        Test.startTest();
        Id id = TaskManagementController.createTask('', null);
        Test.stopTest();
        System.assertEquals(null, id);
    }
}
