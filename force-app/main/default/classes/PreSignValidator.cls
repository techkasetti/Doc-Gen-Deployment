public with sharing class PreSignValidator {
    public static Map<String,Object> validateReadyForSign(Id documentId) {
        Map<String,Object> out = new Map<String,Object>{'ok'=>false,'messages'=>new List<String>()};
        if (documentId == null) { ((List<String>)out.get('messages')).add('documentId missing'); return out; }
        // stub checks
        out.put('ok', true);
        ((List<String>)out.get('messages')).add('pre-sign checks passed (stub)');
        return out;
    }
}