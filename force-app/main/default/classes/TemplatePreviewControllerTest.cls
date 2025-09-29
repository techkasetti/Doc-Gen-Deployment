@IsTest
private class TemplatePreviewControllerTest {
    @IsTest static void testPreviewTemplate_null() {
        Test.startTest();
        String s = TemplatePreviewController.previewTemplate(null, new Map<String,Object>());
        Test.stopTest();
        System.assertEquals(null, s);
    }
}
