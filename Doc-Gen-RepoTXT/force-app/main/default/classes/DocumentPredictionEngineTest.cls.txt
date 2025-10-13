@IsTest
private class DocumentPredictionEngineTest {
    @IsTest static void testPredictNull() {
        Test.startTest();
        Decimal s = DocumentPredictionEngine.predictComplexity(null);
        Test.stopTest();
        System.assertEquals(0.0, s);
    }
    @IsTest static void testPredictFlow() {
        Id docId = null;
        if (Schema.getGlobalDescribe().containsKey('Document__c')) {
            Document__c d = new Document__c(Name='Short'); insert d; docId = d.Id;
        }
        Test.startTest();
        Decimal s = DocumentPredictionEngine.predictComplexity(docId);
        Test.stopTest();
        System.assert(s >= 0.0);
    }
}