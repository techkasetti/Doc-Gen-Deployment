@isTest
private class CrossPlatformControllerTest {
    @isTest static void testSendNotification_invalid() {
        Test.startTest();
        Map<String,Object> r = CrossPlatformController.sendNotification('', '', 'hi');
        Test.stopTest();
        System.assertEquals(false, r.get('sent'));
    }
    @isTest static void testSendNotification_ok() {
        Test.startTest();
        Map<String,Object> r = CrossPlatformController.sendNotification('iOS', 'dev1', 'hello');
        Test.stopTest();
        System.assertEquals(true, r.get('sent'));
    }
}