@isTest
private class CrossPlatformConnectorTest {
    @isTest static void testSupportedPlatforms() {
        Test.startTest();
        List<String> l = CrossPlatformConnector.supportedPlatforms();
        Test.stopTest();
        System.assert(l.contains('iOS'));
    }
    @isTest static void testRegisterDevice_invalid() {
        Test.startTest();
        Boolean ok = CrossPlatformConnector.registerDevice('', '', null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}