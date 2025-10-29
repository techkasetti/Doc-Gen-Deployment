@isTest
private class CybersecurityControllerTest {
    @isTest static void testScanForThreats() {
        Test.startTest();
        Map<String,Object> r = CybersecurityController.scanForThreats('t1');
        Test.stopTest();
        System.assert(r.containsKey('threats'));
    }
}