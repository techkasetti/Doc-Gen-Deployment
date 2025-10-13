@IsTest
private class TenantUsageSyncServiceTest {
    @IsTest static void testSyncUsageForTenant_null() {
        Test.startTest();
        Boolean ok = TenantUsageSyncService.syncUsageForTenant(null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
