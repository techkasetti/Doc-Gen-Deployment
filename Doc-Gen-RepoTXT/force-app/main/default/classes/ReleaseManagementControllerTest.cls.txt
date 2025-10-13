@IsTest
private class ReleaseManagementControllerTest {
    @IsTest static void testListReleases_default() {
        Test.startTest();
        Map<String,Object> r = ReleaseManagementController.listReleases(null);
        Test.stopTest();
        System.assertEquals(true, r.get('ok'));
    }
}
