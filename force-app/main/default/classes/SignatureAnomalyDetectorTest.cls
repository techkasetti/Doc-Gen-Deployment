@IsTest
private class SignatureAnomalyDetectorTest {
    @IsTest static void testDetectFlow() {
        Test.startTest();
        Boolean a = SignatureAnomalyDetector.detect(new Map<String,Object>{'velocity' => 10});
        Test.stopTest();
        System.assertEquals(false, a);
    }
}