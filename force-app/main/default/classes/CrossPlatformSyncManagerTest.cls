@isTest
private class CrossPlatformSyncManagerTest {
    @isTest static void testStartSync() {
        Test.startTest();
        Map<String,Object> r = CrossPlatformSyncManager.startSync('Android', 100);
        Test.stopTest();
        System.assertEquals(true, r.get('started'));
    }
}