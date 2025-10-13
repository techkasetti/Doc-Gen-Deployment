@IsTest
private class RegionalTaxComplianceServiceTest {
    @IsTest static void testComputeTax_invalid() {
        Test.startTest();
        Map<String,Object> r = RegionalTaxComplianceService.computeTax('', null);
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
