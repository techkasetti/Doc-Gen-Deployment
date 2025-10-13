@IsTest
private class ProductionSupportManagerTest {
    @IsTest static void testOpenIncident_invalid() {
        Test.startTest();
        Map<String,Object> r = ProductionSupportManager.openIncident('', null);
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
