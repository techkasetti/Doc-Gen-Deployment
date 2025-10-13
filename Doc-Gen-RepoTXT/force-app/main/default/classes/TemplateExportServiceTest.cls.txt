@IsTest
private class TemplateExportServiceTest {
    @IsTest static void testExportTemplate_null() {
        Test.startTest();
        Id id = TemplateExportService.exportTemplate(null);
        Test.stopTest();
        System.assertEquals(null, id);
    }
}
