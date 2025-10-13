@IsTest
private class OperatorJobControllerTest {
    @IsTest static void testListRecentJobs() {
        Test.startTest();
        List<Job_Run__c> rows = OperatorJobController.listRecentJobs(7);
        Test.stopTest();
        System.assertNotEquals(null, rows);
    }
}
