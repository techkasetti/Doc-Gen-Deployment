@isTest
private class AdvancedSecurityControllerTest {
    @isTest static void testAnalyzeSecurity_missing() {
        Test.startTest();
        Map<String,Object> r = AdvancedSecurityController.analyzeSecurity posture('');
        Test.stopTest();
        System.assertEquals('error', r.get('status'));
    }
}
