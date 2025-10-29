@isTest
private class AIDocumentIntelligenceEngineTest {
    @isTest static void testAnalyzeDocument_invalid() {
        Test.startTest();
        Map<String,Object> r = AIDocumentIntelligenceEngine.analyzeDocument('', null);
        Test.stopTest();
        System.assertEquals('error', r.get('status'));
    }
    @isTest static void testAnalyzeDocument_ok() {
        Test.startTest();
        Map<String,Object> r = AIDocumentIntelligenceEngine.analyzeDocument('doc1', null);
        Test.stopTest();
        System.assertEquals('analyzed', r.get('status'));
    }
}