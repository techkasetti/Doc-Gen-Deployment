@isTest
private class CachingStrategyControllerTest {
    @isTest static void testRecommendStrategy() {
        Test.startTest();
        Map<String,Object> r = CachingStrategyController.recommendStrategy('docgen');
        Test.stopTest();
        System.assert(r.containsKey('strategy'));
    }
}