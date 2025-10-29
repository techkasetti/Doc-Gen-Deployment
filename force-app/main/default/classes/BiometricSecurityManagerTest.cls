@isTest
private class BiometricSecurityManagerTest {
    @isTest static void testEnrollBiometric_invalid() {
        Test.startTest();
        Map<String,Object> r = BiometricSecurityManager.enrollBiometric('', null);
        Test.stopTest();
        System.assertEquals(false, r.get('enrolled'));
    }
}