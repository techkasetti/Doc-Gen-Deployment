public with sharing class ClauseSuggestionController {
    @AuraEnabled public static Map<String,Object> getSuggestions(Id documentId, Integer k) {
        Map<String,Object> out = new Map<String,Object>{'ok'=>false,'suggestions'=>null};
        if (documentId == null) { out.put('ok', false); return out; }
        List<String> s = ClauseSuggestionEngine.suggestClauses(documentId, k);
        out.put('ok', true); out.put('suggestions', s);
        return out;
    }
}