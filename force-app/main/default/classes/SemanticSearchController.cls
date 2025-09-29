public with sharing class SemanticSearchController {
    @AuraEnabled public static List<Map<String,Object>> semanticSearch(String query, Integer topK) {
        if (String.isBlank(query)) return new List<Map<String,Object>>();
        return new List<Map<String,Object>>{ new Map<String,Object>{'id'=>'', 'score'=>0.0} };
    }
}
