@isTest
private class BlockchainControllerTest {
    @isTest static void testCreateAnchor_invalid() {
        Test.startTest();
        Map<String,Object> r = BlockchainController.createAnchor(new List<Id>());
        Test.stopTest();
        System.assertEquals('error', r.get('status'));
    }
    @isTest static void testCreateAnchor_ok() {
        Test.startTest();
        Map<String,Object> r = BlockchainController.createAnchor(new List<Id>{Id.valueOf('001000000000000AAA')});
        Test.stopTest();
        System.assertEquals('created', r.get('status'));
    }
}