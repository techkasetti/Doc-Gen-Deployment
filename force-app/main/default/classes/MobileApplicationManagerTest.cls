@IsTest
private class MobileApplicationManagerTest {
    @IsTest static void testRegisterApp_invalid() {
        Test.startTest();
        Boolean ok = MobileApplicationManager.registerApp('', null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
