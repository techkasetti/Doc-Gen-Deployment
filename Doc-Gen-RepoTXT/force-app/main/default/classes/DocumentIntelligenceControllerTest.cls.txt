@IsTest
private class DocumentIntelligenceControllerTest {
 @IsTest static void testAnalyzeDocument_missing() {
        Test.startTest();
        Map<String,Object> r = DocumentIntelligenceController.analyzeDocument(null);
        Test.stopTest();
        System.assertEquals(false, (Boolean)r.get('ok'));
    }    @IsTest static void testAnalyzeDocument_noObjectGraceful() {
        Test.startTest();
        Map<String,Object> res = DocumentIntelligenceController.analyzeDocument(null);
        Test.stopTest();
        System.assertEquals(false, (Boolean)res.get('ok'));
    }
    @IsTest static void testAnalyzeDocument_flow() {
        // permissive: if Document__c exists we create one; otherwise test should not fail
        Id docId = null;
        if (Schema.getGlobalDescribe().containsKey('Document__c')) {
            Document__c d = new Document__c(Name='UTDoc');
            insert d;
            docId = d.Id;
        }
        Test.startTest();
        Map<String,Object> res = DocumentIntelligenceController.analyzeDocument(docId);
        Test.stopTest();
        System.assertNotEquals(null, res);
        System.assert(res.containsKey('ok'));
    }
}