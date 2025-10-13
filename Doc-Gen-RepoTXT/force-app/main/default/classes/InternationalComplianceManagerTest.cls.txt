@IsTest
private class InternationalComplianceManagerTest {
    @IsTest static void testValidateForRegion_invalid() {
        Test.startTest();
        Map<String,Object> r = InternationalComplianceManager.validateForRegion('', null);
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
