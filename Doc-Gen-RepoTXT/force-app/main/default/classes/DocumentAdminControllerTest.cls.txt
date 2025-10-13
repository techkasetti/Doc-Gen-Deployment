@IsTest
private class DocumentAdminControllerTest {
    @IsTest static void testAdminHealth() {
        Test.startTest();
        Map<String,Object> r = DocumentAdminController.adminHealth();
        Test.stopTest();
        System.assertEquals(true, (Boolean)r.get('ok'));
    }
}