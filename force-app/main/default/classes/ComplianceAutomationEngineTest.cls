@isTest
private class ComplianceAutomationEngineTest {
    @isTest static void testRunAutomations() {
        Test.startTest();
        Map<String,Object> r = ComplianceAutomationEngine.runAutomations('rs1');
        Test.stopTest();
        System.assertEquals('executed', r.get('status'));
    }
}
