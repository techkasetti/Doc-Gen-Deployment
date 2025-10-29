@IsTest
private class BillingAdjustmentServiceTest {
    @IsTest static void testApplyAdjustment_invalid() {
        Test.startTest();
        Boolean ok = BillingAdjustmentService.applyAdjustment(null, null, null);
        Test.stopTest();
        System.assertEquals(false, ok);
    }
}