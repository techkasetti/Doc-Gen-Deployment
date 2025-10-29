public with sharing class ThreatDetectionService {
    public class DetectionResult {
        public Boolean ok;
        public List<String> indicators;
        public String summary;
    }

    @AuraEnabled
    public static DetectionResult analyzePayload(Map<String,Object> payload) {
        DetectionResult res = new DetectionResult();
        res.ok = false;
        res.indicators = new List<String>();
        try {
            if (payload == null || payload.isEmpty()) return res;
            // Simple heuristic placeholders - replace with production ML/heuristics
            String raw = JSON.serialize(payload);
            if (raw.contains('malware') || raw.contains('sql_injection')) res.indicators.add('suspicious_payload');
            if (res.indicators.isEmpty()) {
                res.summary = 'No obvious threats detected';
            } else {
                res.summary = 'Indicators found: ' + String.join(res.indicators, ',');
            }
            res.ok = true;
            return res;
        } catch (Exception ex) {
            try {
                if (Schema.getGlobalDescribe().containsKey('Error_Log__c')) {
                    insert new Error_Log__c(Message__c = 'ThreatDetectionService:' + ex.getMessage());
                }
            } catch (Exception e) {}
            res.summary = 'error: ' + ex.getMessage();
            return res;
        }
    }
}