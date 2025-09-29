@IsTest
private class MicroservicesArchitectureManagerTest {
    @IsTest static void testGetTopology() {
        Test.startTest();
        Map<String,Object> r = MicroservicesArchitectureManager.getTopology();
        Test.stopTest();
        System.assertEquals(true, r.get('ok'));
    }
}
