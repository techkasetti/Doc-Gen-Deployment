public with sharing class AIResolutionService {
    @AuraEnabled
    public static Map<String,Object> resolveAmbiguity(String contextId, Map<String,Object> data) {
        Map<String,Object> out = new Map<String,Object>{ 'contextId' => contextId, 'resolution' => 'deferred' };
        if (String.isBlank(contextId)) return out;
        // TODO: call LLM or heuristic router; return resolution and confidence
        out.put('resolution','apply_default');
        out.put('confidence', 0.75);
        return out;
    }
}
