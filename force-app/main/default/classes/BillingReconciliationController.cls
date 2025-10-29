public with sharing class BillingReconciliationController {
    @AuraEnabled
    public static Map<String,Object> reconcileInvoice(String invoiceHash) {
        Map<String,Object> out = new Map<String,Object>{'ok'=>false};
        if (String.isBlank(invoiceHash)) { out.put('error','missing'); return out; }
        // stub: call reconciliation; here return ok
        out.put('ok', true);
        out.put('reconciled', true);
        return out;
    }
}