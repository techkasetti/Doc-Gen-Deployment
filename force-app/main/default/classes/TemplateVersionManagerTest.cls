@IsTest
private class TemplateVersionManagerTest {
    @IsTest static void testCreateVersion_noObject() {
        Test.startTest();
        Id id = TemplateVersionManager.createVersion(null, null);
        Test.stopTest();
        System.assertEquals(null, id);
    }
}