@IsTest
private class TemplateRendererServiceTest {
    @IsTest static void testRenderNull() {
        Test.startTest();
        String h = TemplateRendererService.renderToHtml(null, null);
        Test.stopTest();
        System.assertEquals(null, h);
    }
}