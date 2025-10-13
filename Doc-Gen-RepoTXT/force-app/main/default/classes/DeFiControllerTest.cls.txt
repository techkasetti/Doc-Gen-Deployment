@isTest
private class DeFiControllerTest {
    @isTest static void testGetDefiPosition() {
        Test.startTest();
        Map<String,Object> r = DeFiController.getDefiPosition('acct1');
        Test.stopTest();
        System.assert(r.containsKey('positions'));
    }
}
