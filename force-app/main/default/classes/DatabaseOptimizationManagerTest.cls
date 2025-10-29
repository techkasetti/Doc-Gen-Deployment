@isTest
private class DatabaseOptimizationManagerTest {
    @isTest static void testGetOptimizationSuggestions() {
        Test.startTest();
        Map<String,Object> r = DatabaseOptimizationManager.getOptimizationSuggestions('tenant');
        Test.stopTest();
        System.assert(((List<String>) r.get('suggestions')).size() > 0);
    }
}