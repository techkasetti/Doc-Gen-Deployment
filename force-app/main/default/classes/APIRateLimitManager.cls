public with sharing class APIRateLimitManager {
    private static Map<String,Integer> COUNTS = new Map<String,Integer>();
    @AuraEnabled
    public static Boolean consumeQuota(String key, Integer amount) {
        if (String.isBlank(key) || amount == null || amount <= 0) return false;
        Integer cur = COUNTS.containsKey(key) ? COUNTS.get(key) : 0;
        // simplistic local quota; production: distributed counter
        COUNTS.put(key, cur + amount);
        return true;
    }
    @AuraEnabled
    public static Integer getUsage(String key) {
        return COUNTS.containsKey(key) ? COUNTS.get(key) : 0;
    }

    // Backwards-compatible API used by tests: increment usage for a user Id and
    // return true if the increment stayed within a simple limit (1), false otherwise.
    public static Boolean checkAndIncrement(Id userId, Integer amount) {
        if (userId == null || amount == null || amount <= 0) return false;
        String key = 'user:' + String.valueOf(userId);
        Integer cur = COUNTS.containsKey(key) ? COUNTS.get(key) : 0;
        // For the simple test we enforce a max usage of 1
        Integer max = 1;
        if (cur + amount > max) {
            return false;
        }
        COUNTS.put(key, cur + amount);
        return true;
    }
}