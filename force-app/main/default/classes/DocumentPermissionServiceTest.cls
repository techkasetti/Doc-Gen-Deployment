@IsTest
private class DocumentPermissionServiceTest {
    @IsTest static void testGrantPermission() {
        Test.startTest();
        Boolean ok = DocumentPermissionService.grantPermission(null, null, null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}