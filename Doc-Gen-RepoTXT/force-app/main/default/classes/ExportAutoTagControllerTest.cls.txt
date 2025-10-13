@IsTest
private class ExportAutoTagControllerTest {
    @IsTest static void testRunAutoTag_null() {
        Test.startTest();
        Boolean ok = ExportAutoTagController.runAutoTag(null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
