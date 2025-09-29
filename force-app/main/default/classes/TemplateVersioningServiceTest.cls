@IsTest
private class TemplateVersioningServiceTest {
    @IsTest static void testCreateVersion_null() {
        Test.startTest();
        Id id = TemplateVersioningService.createVersion(null, 'b');
        Test.stopTest();
        System.assertEquals(null, id);
    }
}
