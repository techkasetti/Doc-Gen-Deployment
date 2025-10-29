@IsTest
private class BillingReconciliationControllerTest {
    @IsTest static void testReconcileInvoice_missing() {
        Test.startTest();
        Map<String,Object> r = BillingReconciliationController.reconcileInvoice(null);
        Test.stopTest();
        System.assertEquals(false, r.get('ok'));
    }
}