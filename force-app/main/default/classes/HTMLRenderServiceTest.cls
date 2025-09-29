@IsTest
private class HTMLRenderServiceTest {
    @IsTest static void testSanitizeHtml() {
        Test.startTest();
        String s = HTMLRenderService.sanitizeHtml('<b>ok</b>');
        Test.stopTest();
        System.assertEquals('<b>ok</b>', s);
    }
}