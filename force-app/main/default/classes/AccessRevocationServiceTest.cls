@IsTest
private class AccessRevocationServiceTest {
    @IsTest static void testRevokeAccessForUser_null() {
        Test.startTest();
        Boolean ok = AccessRevocationService.revokeAccessForUser(null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
