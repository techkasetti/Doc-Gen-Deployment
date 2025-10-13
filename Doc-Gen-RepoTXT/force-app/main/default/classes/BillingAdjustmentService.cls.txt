public with sharing class BillingAdjustmentService {
    public static Boolean applyAdjustment(Id invoiceId, Decimal amount, String reason) {
        if (invoiceId == null || amount == null) return false;
        // stub: persist adjustment in Billing_Adjustment__c if exists
        return true;
    }
}
