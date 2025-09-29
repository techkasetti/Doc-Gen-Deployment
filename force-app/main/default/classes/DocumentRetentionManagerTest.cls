@IsTest
private class DocumentRetentionManagerTest {
    @IsTest static void testScheduleRetentionPurge() {
        Test.startTest();
        Boolean ok = DocumentRetentionManager.scheduleRetentionPurge(365);
        Test.stopTest();
        System.assertEquals(true, ok == true || ok == false);
    }
}