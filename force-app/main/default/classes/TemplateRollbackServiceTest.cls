@IsTest
private class TemplateRollbackServiceTest {
    @IsTest static void testRollbackToVersion_null() {
        Test.startTest();
        Boolean ok = TemplateRollbackService.rollbackToVersion(null, null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
