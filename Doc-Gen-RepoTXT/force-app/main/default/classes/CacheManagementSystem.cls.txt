public with sharing class CacheManagementSystem {
    private static Map<String,Object> LOCAL = new Map<String,Object>();
    @AuraEnabled
    public static Object get(String key) {
        if (LOCAL.containsKey(key)) return LOCAL.get(key);
        return null;
    }
    @AuraEnabled
    public static void put(String key, Object value) {
        LOCAL.put(key, value);
    }
    @AuraEnabled
    public static void invalidate(String key) {
        LOCAL.remove(key);
    }
}
