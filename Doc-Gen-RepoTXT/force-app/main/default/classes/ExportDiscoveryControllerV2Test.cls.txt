@IsTest
private class ExportDiscoveryControllerV2Test {
    @IsTest static void testDiscoverRecent() {
        Test.startTest();
        List<Map<String,Object>> r = ExportDiscoveryControllerV2.discoverRecent(7);
        Test.stopTest();
        System.assertNotEquals(null, r);
    }
}
