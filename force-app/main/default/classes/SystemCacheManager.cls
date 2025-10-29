public with sharing class SystemCacheManager {
    private static final String CACHE_PARTITION = 'SystemHealth';
    // Well-known keys we manage in the partition
    private static final List<String> KNOWN_KEYS = new List<String>{
        CACHE_PARTITION + '.currentHealth',
        CACHE_PARTITION + '.performanceMetrics',
        CACHE_PARTITION + '.activeAlerts'
    };

    // Clear known caches (best-effort) using supported Cache.Org.remove(...)
    public static void clearAllCaches() {
        try {
            for (String key : KNOWN_KEYS) {
                try {
                    Cache.Org.remove(key);
                } catch (Exception eRemove) {
                    // ignore per-key failure and continue
                    System.debug('SystemCacheManager.clearAllCaches: remove failed for ' + key + ': ' + eRemove.getMessage());
                }
            }
            // Also attempt to remove a likely session key (defensive)
            try {
                Cache.Session.remove(CACHE_PARTITION + '.currentHealth');
            } catch (Exception eSession) {
                System.debug('SystemCacheManager.clearAllCaches: session remove failed: ' + eSession.getMessage());
            }
            System.debug('SystemCacheManager.clearAllCaches: best-effort cache clear completed.');
        } catch (Exception e) {
            System.debug('SystemCacheManager.clearAllCaches: overall failure: ' + e.getMessage());
        }
    }

    // Cache health data with TTL (seconds)
    public static void cacheHealthData(String key, Object data, Integer ttlSeconds) {
        try {
            Cache.Org.put(CACHE_PARTITION + '.' + key, data, ttlSeconds);
        } catch (Exception e) {
            System.debug('SystemCacheManager.cacheHealthData: Cache storage failed for key ' + key + ': ' + e.getMessage());
        }
    }

    // Retrieve cached health data
    public static Object getCachedHealthData(String key) {
        try {
            return Cache.Org.get(CACHE_PARTITION + '.' + key);
        } catch (Exception e) {
            System.debug('SystemCacheManager.getCachedHealthData: Cache retrieval failed for key ' + key + ': ' + e.getMessage());
            return null;
        }
    }

    // Invalidate a specific cache key
    public static void invalidateCache(String key) {
        try {
            Cache.Org.remove(CACHE_PARTITION + '.' + key);
            System.debug('SystemCacheManager.invalidateCache: Cache invalidated for key: ' + key);
        } catch (Exception e) {
            System.debug('SystemCacheManager.invalidateCache: Cache invalidation failed for key ' + key + ': ' + e.getMessage());
        }
    }

    // Return a best-effort cache "statistics" object without partition APIs
    public static Map<String, Object> getCacheStatistics() {
        Map<String, Object> stats = new Map<String, Object>();
        try {
            // Attempt to read a known cached value to infer availability
            Object cur = null;
            try {
                cur = Cache.Org.get(CACHE_PARTITION + '.currentHealth');
            } catch (Exception eGet) {
                // treat as not available if get throws
                stats.put('isAvailable', false);
                stats.put('error', 'Cache get() failed: ' + eGet.getMessage());
                return stats;
            }
            // If get returned fine, mark available and include basic counts
            stats.put('isAvailable', true);
            stats.put('partition', CACHE_PARTITION);
            stats.put('hasCurrentHealth', cur != null);
            // include whether other known keys exist (best-effort)
            try {
                stats.put('hasPerformanceMetrics', Cache.Org.get(CACHE_PARTITION + '.performanceMetrics') != null);
                stats.put('hasActiveAlerts', Cache.Org.get(CACHE_PARTITION + '.activeAlerts') != null);
            } catch (Exception eMinor) {
                stats.put('note', 'Could not check some keys: ' + eMinor.getMessage());
            }
        } catch (Exception e) {
            stats.put('isAvailable', false);
            stats.put('error', e.getMessage());
        }
        return stats;
    }

    // Optimize cache performance: clear expired entries (placeholder) + preload critical data
    public static void optimizeCachePerformance() {
        try {
            clearExpiredEntries();
            preloadCriticalData();
            System.debug('SystemCacheManager.optimizeCachePerformance: completed.');
        } catch (Exception e) {
            System.debug('SystemCacheManager.optimizeCachePerformance: failed: ' + e.getMessage());
        }
    }

    // Placeholder for expired-entry eviction if you track keys/ttls externally
    private static void clearExpiredEntries() {
        System.debug('SystemCacheManager.clearExpiredEntries: placeholder (no partition.clear() used).');
    }

    // Preload critical system data into cache — uses only Cache.Org and safe dynamic SOQL fallbacks
    private static void preloadCriticalData() {
        try {
            // 1) Try to produce a simple performance metrics aggregate via dynamic SOQL (best-effort)
            try {
                String soql = 'SELECT AVG(Response_Time_Ms__c) avgResponseTime FROM API_Request_Log__c WHERE CreatedDate >= ' +
                    ':DateTime.now().addHours(-1)';
                // Use Database.query for dynamic form; wrap in try/catch because object/fields may not exist
                List<AggregateResult> agg = Database.query(soql);
                Decimal avgResponse = null;
                if (!agg.isEmpty() && agg[0].get('avgResponseTime') != null) {
                    avgResponse = (Decimal)agg[0].get('avgResponseTime');
                }
                Map<String, Object> perf = new Map<String, Object>();
                perf.put('avgResponseMs', avgResponse);
                cacheHealthData('performanceMetrics', perf, 600); // 10 minutes
            } catch (Exception ePerfAgg) {
                System.debug('SystemCacheManager.preloadCriticalData: performance aggregate failed: ' + ePerfAgg.getMessage());
            }

            // 2) Cache active alerts by querying System_Alert__c if that sObject exists
            try {
                Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
                if (gd.containsKey('System_Alert__c')) {
                    // Use only very safe fields that are likely present: Id, Name, Status__c, CreatedDate
                    String q = 'SELECT Id, Name, Status__c, CreatedDate FROM System_Alert__c WHERE Status__c = \'ACTIVE\' ORDER BY CreatedDate DESC LIMIT 50';
                    List<SObject> alerts = Database.query(q);
                    cacheHealthData('activeAlerts', alerts, 180); // 3 minutes
                } else {
                    System.debug('SystemCacheManager.preloadCriticalData: System_Alert__c not present in describe; skipping alert preload.');
                }
            } catch (Exception eAlerts) {
                System.debug('SystemCacheManager.preloadCriticalData: alert query/cache failed: ' + eAlerts.getMessage());
            }

            // 3) Optionally cache a placeholder health object so reads succeed even if no monitor class exists
            try {
                Map<String, Object> placeholder = new Map<String, Object>{
                    'timestamp' => DateTime.now(),
                    'status' => 'OK',
                    'note' => 'preloaded by SystemCacheManager fallback'
                };
                cacheHealthData('currentHealth', placeholder, 300); // 5 minutes
            } catch (Exception ePlaceholder) {
                System.debug('SystemCacheManager.preloadCriticalData: placeholder cache failed: ' + ePlaceholder.getMessage());
            }

            System.debug('SystemCacheManager.preloadCriticalData: best-effort preloading done.');
        } catch (Exception e) {
            System.debug('SystemCacheManager.preloadCriticalData: failed: ' + e.getMessage());
        }
    }
}