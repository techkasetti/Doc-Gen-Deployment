@IsTest
private class DocumentPreviewControllerTest {
    @IsTest static void testGetPreviewNull() {
        Test.startTest();
        Map<String,Object> r = DocumentPreviewController.getPreview(null);
        Test.stopTest();
        System.assertEquals(false, (Boolean)r.get('ok'));
    }
}