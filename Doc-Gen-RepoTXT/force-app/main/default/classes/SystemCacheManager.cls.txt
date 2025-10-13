public class SystemCacheManager {
    private static final String CACHE_PARTITION = 'SystemHealth';

    // Clear all caches
    public static void clearAllCaches() {
        try {
            // Clear organization cache
            Cache.Org.clear();

            // Clear session cache if applicable
            if (Cache.Session.contains('healthData')) {
                Cache.Session.remove('healthData');
            }

            System.debug('✓ All system caches cleared');
        } catch (Exception e) {
            System.debug('Cache clearing failed: ' + e.getMessage());
        }
    }

    // Cache health data with TTL
    public static void cacheHealthData(String key, Object data, Integer ttlSeconds) {
        try {
            Cache.Org.put(CACHE_PARTITION + '.' + key, data, ttlSeconds);
        } catch (Exception e) {
            System.debug('Cache storage failed for key ' + key + ': ' + e.getMessage());
        }
    }

    // Retrieve cached health data
    public static Object getCachedHealthData(String key) {
        try {
            return Cache.Org.get(CACHE_PARTITION + '.' + key);
        } catch (Exception e) {
            System.debug('Cache retrieval failed for key ' + key + ': ' + e.getMessage());
            return null;
        }
    }

    // Invalidate a specific cache key
    public static void invalidateCache(String key) {
        try {
            Cache.Org.remove(CACHE_PARTITION + '.' + key);
            System.debug('Cache invalidated for key: ' + key);
        } catch (Exception e) {
            System.debug('Cache invalidation failed for key ' + key + ': ' + e.getMessage());
        }
    }

    // Retrieve cache statistics
    public static Map<String, Object> getCacheStatistics() {
        Map<String, Object> stats = new Map<String, Object>();
        try {
            // Get cache partition statistics
            Cache.OrgPartition partition = Cache.Org.getPartition(CACHE_PARTITION);
            if (partition != null) {
                stats.put('partition', CACHE_PARTITION);
                stats.put('isAvailable', true);
                stats.put('lastAccessed', DateTime.now());
            } else {
                stats.put('isAvailable', false);
                stats.put('error', 'Cache partition not available');
            }
        } catch (Exception e) {
            stats.put('isAvailable', false);
            stats.put('error', e.getMessage());
        }
        return stats;
    }

    // Optimize cache performance
    public static void optimizeCachePerformance() {
        try {
            // Clear expired entries
            clearExpiredEntries();

            // Preload frequently accessed data
            preloadCriticalData();

            System.debug('✓ Cache performance optimization completed');
        } catch (Exception e) {
            System.debug('Cache optimization failed: ' + e.getMessage());
        }
    }

    // Clear expired cache entries (placeholder implementation)
    private static void clearExpiredEntries() {
        // This would clear expired cache entries
        // In a real implementation, you'd track cache expiration times
        System.debug('Clearing expired cache entries...');
    }

    // Preload critical system data into cache
    private static void preloadCriticalData() {
        try {
            // Preload system health data
            SystemHealthMonitor.SystemHealthWrapper health = SystemHealthMonitor.getCompleteSystemHealth();
            cacheHealthData('currentHealth', health, 300); // 5 minutes

            // Preload performance metrics
            Map<String, Object> performanceMetrics = SystemHealthMonitor.getPerformanceMetrics();
            cacheHealthData('performanceMetrics', performanceMetrics, 600); // 10 minutes

            // Preload active alerts
            List<System_Alert__c> activeAlerts = SystemHealthMonitor.getActiveSystemAlerts();
            cacheHealthData('activeAlerts', activeAlerts, 180); // 3 minutes

            System.debug('✓ Critical data preloaded to cache');
        } catch (Exception e) {
            System.debug('Cache preloading failed: ' + e.getMessage());
        }
    }
}
