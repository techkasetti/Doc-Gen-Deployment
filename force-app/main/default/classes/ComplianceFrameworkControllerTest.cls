@isTest
private class ComplianceFrameworkControllerTest {
    @isTest static void testGetFramework() {
        Test.startTest();
        Map<String,Object> r = ComplianceFrameworkController.getFramework('US');
        Test.stopTest();
        System.assertEquals('general', r.get('framework'));
    }
}
