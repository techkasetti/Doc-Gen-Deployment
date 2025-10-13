@IsTest
private class ResourceManagementControllerTest {
    @IsTest static void testListResources() {
        Test.startTest();
        Map<String,Object> r = ResourceManagementController.listResources();
        Test.stopTest();
        System.assertEquals(true, r.get('ok'));
    }
}
