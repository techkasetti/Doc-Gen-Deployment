@isTest
private class ConnectedVehicleControllerTest {
    @isTest static void testGetTelematics() {
        Test.startTest();
        Map<String,Object> r = ConnectedVehicleController.getTelematics('veh1');
        Test.stopTest();
        System.assertEquals(true, r.get('connected'));
    }
}
