@isTest
private class ComputerVisionControllerTest {
    @isTest static void testAnalyzeImage_invalid() {
        Test.startTest();
        Map<String,Object> r = ComputerVisionController.analyzeImage('');
        Test.stopTest();
        System.assertEquals('error', r.get('status'));
    }
}