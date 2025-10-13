@IsTest
private class ModelDriftDetectorTest {
    @IsTest static void testDetectDrift_null() {
        Test.startTest();
        Boolean ok = ModelDriftDetector.detectDrift(null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
