@IsTest
private class MobileIntegrationManagerTest {
    @IsTest static void testListMobileIntegrations() {
        Test.startTest();
        Map<String,Object> r = MobileIntegrationManager.listMobileIntegrations();
        Test.stopTest();
        System.assertEquals(true, r.get('ok'));
    }
}
