@IsTest
private class TemplateDiffServiceTest {
    @IsTest static void testDiffVersions_null() {
        Test.startTest();
        Map<String,Object> r = TemplateDiffService.diffVersions(null, null);
        Test.stopTest();
        System.assertEquals(true, r.get('ok'));
    }
}
