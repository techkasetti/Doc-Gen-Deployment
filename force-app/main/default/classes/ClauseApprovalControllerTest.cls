@IsTest
private class ClauseApprovalControllerTest {
    @IsTest static void testSubmitForApproval_null() {
        Test.startTest();
        Boolean ok = ClauseApprovalController.submitForApproval(null, null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}