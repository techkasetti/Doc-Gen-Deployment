@IsTest
private class TemplateImportServiceTest {
    @IsTest static void testImportTemplateFromFile_null() {
        Test.startTest();
        Id id = TemplateImportService.importTemplateFromFile(null);
        Test.stopTest();
        System.assertEquals(null, id);
    }
}
