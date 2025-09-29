@IsTest
private class QuantumComputingControllerTest {
    @IsTest static void testGetQuantumStatus() {
        Test.startTest();
        Map<String,Object> r = QuantumComputingController.getQuantumStatus();
        Test.stopTest();
        System.assertEquals(true, r.get('ok'));
    }
}
