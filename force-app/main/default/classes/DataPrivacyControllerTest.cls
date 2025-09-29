@isTest
private class DataPrivacyControllerTest {
    @isTest static void testRequestErasure_invalid() {
        Test.startTest();
        Boolean ok = DataPrivacyController.requestErasure('');
        Test.stopTest();
        System.assertEquals(false, ok);
    }
    @isTest static void testGetPrivacyStatus() {
        Test.startTest();
        Map<String,Object> r = DataPrivacyController.getPrivacyStatus('s1');
        Test.stopTest();
        System.assertEquals('active', r.get('status'));
    }
}
