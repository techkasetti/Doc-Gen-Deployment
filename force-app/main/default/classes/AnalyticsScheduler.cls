public with sharing class AnalyticsScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        try {
            // Small demo: trigger a dashboard refresh (in production iterate over dashboards)
            AnalyticsEngineController.runDashboardRefresh('default-dashboard');
        } catch (Exception ex) {
            // swallow/log for resilience
            System.debug('AnalyticsScheduler error: ' + ex.getMessage());
        }
    }
    // helper to schedule
    public static void scheduleDaily() {
        String cron = '0 0 5 * * ?'; // 5 AM daily
        System.schedule('AnalyticsSchedulerDaily', cron, new AnalyticsScheduler());
    }
}
