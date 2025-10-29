public with sharing class ComplianceChecker {
    // Example rule engine check - returns map with result and messages
    public static Map<String,Object> runChecks(String documentId) {
        Map<String,Object> out = new Map<String,Object>{'ok' => true, 'messages' => new List<String>()};
        // minimal stub: check that documentId is provided
        if (String.isBlank(documentId)) {
            out.put('ok', false);
            ((List<String>)out.get('messages')).add('documentId missing');
        } else {
            ((List<String>)out.get('messages')).add('stub-rule-pass');
        }
        return out;
    }

    // Minimal typed result used by other classes in the repo
    public class ComplianceResult {
        public Decimal complianceScore;
        public Boolean isCompliant;
        public List<String> violations;
        public List<Map<String,Object>> validationResults;

        public ComplianceResult() {
            this.complianceScore = 1.0;
            this.isCompliant = true;
            this.violations = new List<String>();
            this.validationResults = new List<Map<String,Object>>();
        }
    }

    // Minimal validate method to satisfy callers. Real implementation should run checks and populate fields.
    public static ComplianceResult validateDocumentCompliance(String content, String documentType, String jurisdiction) {
        ComplianceResult res = new ComplianceResult();
        try {
            if (String.isBlank(content)) {
                res.complianceScore = 0.0;
                res.isCompliant = false;
                res.violations.add('empty_content');
                res.validationResults.add(new Map<String,Object>{'rule' => 'content_present', 'ok' => false, 'message' => 'Content is empty'});
            } else {
                // stub: everything passes
                res.complianceScore = 0.95;
                res.isCompliant = true;
                res.validationResults.add(new Map<String,Object>{'rule' => 'stub_pass', 'ok' => true, 'message' => 'Stub check passed'});
            }
        } catch (Exception e) {
            res.complianceScore = 0.0;
            res.isCompliant = false;
            res.violations.add('validation_error');
            res.validationResults.add(new Map<String,Object>{'rule' => 'exception', 'ok' => false, 'message' => e.getMessage()});
        }
        return res;
    }
}