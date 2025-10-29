@isTest
private class AutomatedTestingSuiteTest {
    @isTest static void testListSuites() {
        Test.startTest();
        List<String> s = AutomatedTestingSuite.listSuites();
        Test.stopTest();
        System.assert(s.contains('unit'));
    }
}