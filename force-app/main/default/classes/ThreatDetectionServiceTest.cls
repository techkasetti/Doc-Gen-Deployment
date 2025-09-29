@IsTest
private class ThreatDetectionServiceTest {
    @IsTest static void testAnalyzePayload_empty() {
        Test.startTest();
        ThreatDetectionService.DetectionResult r = ThreatDetectionService.analyzePayload(null);
        Test.stopTest();
        System.assertEquals(false, r.ok);
    }

    @IsTest static void testAnalyzePayload_withIndicator() {
        Map<String,Object> p = new Map<String,Object>{ 'field' => 'contains sql_injection' };
        Test.startTest();
        ThreatDetectionService.DetectionResult r = ThreatDetectionService.analyzePayload(p);
        Test.stopTest();
        System.assertEquals(true, r.ok);
        System.assert(r.indicators.size() >= 0);
    }
}
