@IsTest
private class ResponsiveInterfaceManagerTest {
    @IsTest static void testGetInterfaceHints_invalid() {
        Test.startTest();
        Map<String,Object> r = ResponsiveInterfaceManager.getInterfaceHints('');
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}
