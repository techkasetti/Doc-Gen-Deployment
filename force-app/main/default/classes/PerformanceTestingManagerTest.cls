@IsTest
private class PerformanceTestingManagerTest {
    @IsTest static void testRunLoadTest_invalid() {
        Test.startTest();
        Map<String,Object> r = PerformanceTestingManager.runLoadTest('');
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
