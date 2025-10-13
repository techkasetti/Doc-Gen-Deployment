@IsTest
private class ExportDiscoveryControllerTest {
    @IsTest static void testDiscoverRecent() {
        Test.startTest();
        List<Map<String,Object>> r = ExportDiscoveryController.discoverRecent(7);
        Test.stopTest();
        System.assertNotEquals(null, r);
    }
}
