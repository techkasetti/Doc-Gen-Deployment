@IsTest
private class SecurityFrameworkControllerTest {
    @IsTest static void testGetSecurityPosture() {
        Test.startTest();
        Map<String,Object> r = SecurityFrameworkController.getSecurityPosture();
        Test.stopTest();
        System.assertEquals(true, r.get('ok'));
    }
}
