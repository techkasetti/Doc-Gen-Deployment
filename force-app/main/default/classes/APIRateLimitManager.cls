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
}
