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
}
