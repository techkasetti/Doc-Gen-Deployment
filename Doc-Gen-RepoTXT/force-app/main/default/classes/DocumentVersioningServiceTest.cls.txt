@IsTest
private class DocumentVersioningServiceTest {
    @IsTest static void testCreateVersion() {
        Test.startTest();
        Id id = DocumentVersioningService.createVersion(null, null);
        Test.stopTest();
        System.assertEquals(null, id);
    }
}