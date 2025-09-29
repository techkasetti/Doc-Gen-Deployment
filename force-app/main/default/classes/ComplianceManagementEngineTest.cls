@isTest
private class ComplianceManagementEngineTest {
    @isTest static void testEvaluate() {
        Test.startTest();
        Map<String,Object> r = ComplianceManagementEngine.evaluate('US', 'doc1');
        Test.stopTest();
        System.assert(r.containsKey('compliant'));
    }
}
