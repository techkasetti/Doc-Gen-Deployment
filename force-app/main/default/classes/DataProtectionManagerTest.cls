@isTest
private class DataProtectionManagerTest {
    @isTest static void testEncryptRecord_invalid() {
        Test.startTest();
        Boolean ok = DataProtectionManager.encryptRecord('', null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}