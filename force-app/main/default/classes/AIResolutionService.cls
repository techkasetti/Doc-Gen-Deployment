public with sharing class AIResolutionService {

    /**
     * Resolve an ambiguity given a contextId and optional data payload.
     * Preserves the original behavior but centralizes resolution helpers.
     */
    @AuraEnabled
    public static Map<String,Object> resolveAmbiguity(String contextId, Map<String,Object> data) {
        Map<String,Object> out = new Map<String,Object>{ 'contextId' => contextId, 'resolution' => 'deferred' };
        if (String.isBlank(contextId)) return out;

        // Example: try a heuristic quick-resolve using provided data (best-effort)
        try {
            // If callers provided a suggested resolution inside data, prefer it
            if (data != null && data.containsKey('suggestedResolution')) {
                out.put('resolution', String.valueOf(data.get('suggestedResolution')));
                out.put('confidence', data.containsKey('confidence') ? data.get('confidence') : 0.9);
                return out;
            }
        } catch (Exception ex) {
            System.debug('resolveAmbiguity heuristic check failed: ' + ex.getMessage());
        }

        // Default behavior (deferred). Consumers can call generateResolutionSuggestion separately.
        out.put('resolution','apply_default');
        out.put('confidence', 0.75);
        return out;
    }

    /**
     * Generate a resolution suggestion for a serialized AI request payload.
     * - Attempts a callout to the named credential "AnARA_AI_Service" at /resolution
     * - Falls back to a local heuristic if the callout fails
     *
     * Note: this method is usable from Apex (public static). Marked @AuraEnabled if you
     * also want to call it directly from the client-side; remove the annotation if not needed.
     */
    @AuraEnabled
    public static String generateResolutionSuggestion(String aiRequestJson) {
        if (String.isBlank(aiRequestJson)) return 'deferred';

        // Try external AI service via Named Credential: callout:AnARA_AI_Service/resolution
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:AnARA_AI_Service/resolution');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(30 * 1000);
            req.setBody(aiRequestJson);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res != null && res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                // Prefer structured response fields if present
                try {
                    Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                    if (parsed.containsKey('suggestion')) return String.valueOf(parsed.get('suggestion'));
                    if (parsed.containsKey('resolution')) return String.valueOf(parsed.get('resolution'));
                    if (parsed.containsKey('result')) return String.valueOf(parsed.get('result'));
                    // Fallback: return a short excerpt of the raw body
                    String body = res.getBody();
                    return body == null ? 'deferred' : body.substring(0, Math.min(body.length(), 1000));
                } catch (Exception parseEx) {
                    System.debug('AIResolutionService: response parse failed: ' + parseEx.getMessage());
                    String body = res.getBody();
                    return body == null ? 'deferred' : body.substring(0, Math.min(body.length(), 1000));
                }
            } else {
                System.debug('AIResolutionService: AI service returned status ' + (res == null ? 'null' : String.valueOf(res.getStatusCode())));
                // Fall through to heuristic
            }
        } catch (Exception callEx) {
            System.debug('AIResolutionService: callout error: ' + callEx.getMessage());
            // Fall through to heuristic fallback
        }

        // Heuristic fallback
        return performLocalHeuristicResolution(aiRequestJson);
    }

    /**
     * Very small, defensive heuristic used when external AI is unavailable.
     * Examines the serialized aiRequest (expected to contain operation1/operation2)
     * and returns a coarse suggestion string such as 'AUTO_MERGE_FORMATTING',
     * 'AUTO_MERGE_NON_OVERLAPPING', or 'PENDING_HUMAN_REVIEW'.
     */
    private static String performLocalHeuristicResolution(String aiRequestJson) {
        if (String.isBlank(aiRequestJson)) return 'deferred';
        try {
            Map<String, Object> req = (Map<String, Object>) JSON.deserializeUntyped(aiRequestJson);

            if (req.containsKey('operation1') && req.containsKey('operation2')) {
                Map<String, Object> op1 = (Map<String, Object>) req.get('operation1');
                Map<String, Object> op2 = (Map<String, Object>) req.get('operation2');

                String t1 = op1.containsKey('type') ? String.valueOf(op1.get('type')).toUpperCase() : '';
                String t2 = op2.containsKey('type') ? String.valueOf(op2.get('type')).toUpperCase() : '';

                // Formatting-only -> auto-merge formatting
                if (t1 == 'FORMAT' && t2 == 'FORMAT') return 'AUTO_MERGE_FORMATTING';

                // If both inserts at different positions -> non-overlapping
                Integer p1 = null;
                Integer p2 = null;
                if (op1.containsKey('position')) {
                    try { p1 = Integer.valueOf(String.valueOf(op1.get('position'))); } catch (Exception ignore) {}
                }
                if (op2.containsKey('position')) {
                    try { p2 = Integer.valueOf(String.valueOf(op2.get('position'))); } catch (Exception ignore) {}
                }
                if (p1 != null && p2 != null && p1 != p2) return 'AUTO_MERGE_NON_OVERLAPPING';

                // If one is delete and other is insert nearby -> pending review
                if ((t1 == 'DELETE' && t2 == 'INSERT') || (t1 == 'INSERT' && t2 == 'DELETE')) {
                    return 'PENDING_HUMAN_REVIEW';
                }

                // Default conservative fallback
                return 'PENDING_HUMAN_REVIEW';
            }

            // If payload contains an explicit 'suggestedResolution' use it
            if (req.containsKey('suggestedResolution')) return String.valueOf(req.get('suggestedResolution'));

        } catch (Exception ex) {
            System.debug('AIResolutionService.performLocalHeuristicResolution failed: ' + ex.getMessage());
        }
        return 'deferred';
    }
}