@IsTest
private class SecurityManagerTest {
    @IsTest static void testEscalateAlert_invalid() {
        Test.startTest();
        Boolean ok = SecurityManager.escalateAlert('', '');
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
