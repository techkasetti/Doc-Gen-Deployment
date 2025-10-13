@IsTest
private class ResponsiveDesignManagerTest {
    @IsTest static void testApplyLayout_invalid() {
        Test.startTest();
        Boolean ok = ResponsiveDesignManager.applyLayout('');
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}
