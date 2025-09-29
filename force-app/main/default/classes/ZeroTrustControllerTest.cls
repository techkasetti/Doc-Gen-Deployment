@IsTest
private class ZeroTrustControllerTest {
    @IsTest static void testEvaluateTrust_invalid() {
        Test.startTest();
        Map<String,Object> r = ZeroTrustController.evaluateTrust('', '');
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }

    @IsTest static void testEvaluateTrust_ok() {
        Test.startTest();
        Map<String,Object> r = ZeroTrustController.evaluateTrust('user-1', 'res-1');
        Test.stopTest();
        System.assertEquals(true, r.get('ok'));
    }
}
