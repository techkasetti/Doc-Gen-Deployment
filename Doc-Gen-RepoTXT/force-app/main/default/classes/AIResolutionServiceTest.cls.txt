@isTest
private class AIResolutionServiceTest {
    @isTest static void testResolveAmbiguity() {
        Test.startTest();
        Map<String,Object> r = AIResolutionService.resolveAmbiguity('ctx1', null);
        Test.stopTest();
        System.assert(r.containsKey('resolution'));
    }
}
