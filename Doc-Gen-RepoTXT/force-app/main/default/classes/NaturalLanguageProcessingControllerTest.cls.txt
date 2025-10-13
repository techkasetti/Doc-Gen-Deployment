@IsTest
private class NaturalLanguageProcessingControllerTest {
    @IsTest static void testAnalyzeText_invalid() {
        Test.startTest();
        Map<String,Object> r = NaturalLanguageProcessingController.analyzeText('', null);
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
