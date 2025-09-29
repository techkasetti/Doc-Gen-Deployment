@IsTest
private class QuantumNetworkingControllerTest {
    @IsTest static void testGetNetworkTopology() {
        Test.startTest();
        Map<String,Object> r = QuantumNetworkingController.getNetworkTopology();
        Test.stopTest();
        System.assertEquals(true, r.get('ok'));
    }
}
