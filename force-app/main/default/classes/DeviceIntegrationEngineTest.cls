@isTest
private class DeviceIntegrationEngineTest {
    @isTest static void testRegisterIoTDevice() {
        Test.startTest();
        Boolean ok = DeviceIntegrationEngine.registerIoTDevice('dev1', new Map<String,Object>{});
        Test.stopTest();
        System.assertEquals(true, ok);
    }
    @isTest static void testGetDeviceStatus() {
        Test.startTest();
        Map<String,Object> r = DeviceIntegrationEngine.getDeviceStatus('dev1');
        Test.stopTest();
        System.assertEquals('online', r.get('status'));
    }
}