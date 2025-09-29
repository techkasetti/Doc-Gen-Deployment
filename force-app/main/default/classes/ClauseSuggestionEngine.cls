public with sharing class ClauseSuggestionEngine {
    public static List<String> suggestClauses(Id documentId, Integer maxSuggestions) {
        List<String> out = new List<String>();
        if (documentId == null) return out;
        // Stub suggestions
        out.add('Suggested clause 1 for ' + String.valueOf(documentId));
        if (maxSuggestions != null && maxSuggestions > 1) out.add('Suggested clause 2 for ' + String.valueOf(documentId));
        return out;
    }
}