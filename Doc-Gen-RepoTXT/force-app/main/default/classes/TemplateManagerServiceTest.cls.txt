@IsTest
private class TemplateManagerServiceTest {
    @IsTest static void testCreateTemplate_noName() {
        Test.startTest();
        Id id = TemplateManagerService.createTemplate('', 'b', 'en');
        Test.stopTest();
        System.assertEquals(null, id);
    }
}
