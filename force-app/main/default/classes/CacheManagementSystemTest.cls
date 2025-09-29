@isTest
private class CacheManagementSystemTest {
    @isTest static void testPutGetInvalidate() {
        Test.startTest();
        CacheManagementSystem.put('k1', 'v1');
        Object v = CacheManagementSystem.get('k1');
        CacheManagementSystem.invalidate('k1');
        Test.stopTest();
        System.assertEquals('v1', (String)v);
    }
}
