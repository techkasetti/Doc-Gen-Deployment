public with sharing class SignatureAnalyticsService {
    public static Map<String, Integer> computeSignatureMetrics(Id documentId) {
        Map<String, Integer> out = new Map<String, Integer>();
        out.put('totalSignatures', 0);
        out.put('anomalies', 0);
        // stub: in prod query Signature__c and compute metrics
        return out;
    }
}