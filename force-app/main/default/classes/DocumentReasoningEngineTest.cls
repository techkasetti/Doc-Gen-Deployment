@IsTest
private class DocumentReasoningEngineTest {
    @IsTest static void testReasonEmpty() {
        Test.startTest();
        Map<String,Object> res = DocumentReasoningEngine.reasonAcrossDocuments(new List<Id>());
        Test.stopTest();
        System.assertEquals(false, (Boolean)res.get('ok'));
    }
    @IsTest static void testReasonFlow() {
        List<Id> ids = new List<Id>();
        if (Schema.getGlobalDescribe().containsKey('Document__c')) {
            Document__c d = new Document__c(Name='D1'); insert d; ids.add(d.Id);
        }
        Test.startTest();
        Map<String,Object> res = DocumentReasoningEngine.reasonAcrossDocuments(ids);
        Test.stopTest();
        System.assert(res.containsKey('insights'));
    }
}
