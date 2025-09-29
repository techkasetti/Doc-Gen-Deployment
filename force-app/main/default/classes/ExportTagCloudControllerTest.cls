@IsTest
private class ExportTagCloudControllerTest {
    @IsTest static void testCounts() {
        Test.startTest();
        Map<String,Integer> r = ExportTagCloudController.counts(50);
        Test.stopTest();
        System.assertNotEquals(null, r);
    }
}
