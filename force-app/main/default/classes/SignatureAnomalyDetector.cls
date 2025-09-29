public with sharing class SignatureAnomalyDetector {
    public static Boolean detect(Map<String,Object> features) {
        if (features == null) return false;
        // stub heuristics
        if (features.containsKey('velocity') && (Decimal)features.get('velocity') > 100) return true;
        return false;
    }
}