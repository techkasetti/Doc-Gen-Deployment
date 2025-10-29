@IsTest
private class DocumentCollaborationEngineTest {

    @IsTest static void testCreateThread_noObject() {
        Test.startTest();
        Id id = DocumentCollaborationEngine.createThread(null, null, null);
        Test.stopTest();
        System.assertEquals(null, id);
    }
    @IsTest static void testCreateThread_flow() {
        Id docId = null;
        if (Schema.getGlobalDescribe().containsKey('Document__c')) {
            Document__c d = new Document__c(Name='DocC'); insert d; docId = d.Id;
        }
        Test.startTest();
        Id tid = DocumentCollaborationEngine.createThread(docId, 'sub', 'body');
        Test.stopTest();
    }
}