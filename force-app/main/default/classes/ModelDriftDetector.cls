public with sharing class ModelDriftDetector {
    public static Boolean detectDrift(String modelKey) {
        if (String.isBlank(modelKey)) return false;
        // stub: in prod run drift analysis; here return false (no drift)
        return false;
    }
}