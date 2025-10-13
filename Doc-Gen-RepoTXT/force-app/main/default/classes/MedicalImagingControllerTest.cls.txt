@IsTest
private class MedicalImagingControllerTest {
    @IsTest static void testAnalyzeImage_invalid() {
        Test.startTest();
        Map<String,Object> r = MedicalImagingController.analyzeImage(null);
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
