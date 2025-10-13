public with sharing class AnalyticsEngineController {
    @AuraEnabled
    public static Map<String,Object> runDashboardRefresh(String dashboardId) {
        Map<String,Object> out = new Map<String,Object>{ 'dashboardId' => dashboardId, 'status' => 'refresh_queued' };
        if (String.isBlank(dashboardId)) { out.put('status','error'); out.put('error','missing_dashboardId'); return out; }
        // TODO: enqueue job that calls AnalyticsEngine.computeAnalytics for tiles
        out.put('queuedAt', String.valueOf(Datetime.now()));
        return out;
    }
}
