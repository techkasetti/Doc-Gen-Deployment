@IsTest
private class PDFRenderServiceTest {
    @IsTest static void testRenderHtmlToPdf_noContent() {
        Test.startTest();
        Id id = PDFRenderService.renderHtmlToPdf('', null);
        Test.stopTest();
        System.assertEquals(null, id);
    }
}
