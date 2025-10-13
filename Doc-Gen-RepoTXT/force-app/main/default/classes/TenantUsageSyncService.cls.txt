public with sharing class TenantUsageSyncService {
    public static Boolean syncUsageForTenant(Id tenantId) {
        if (tenantId == null) return false;
        // stub: record Integration_Call__c to indicate sync request
        if (Schema.getGlobalDescribe().containsKey('Integration_Call__c')) {
            try { insert new Integration_Call__c(Endpoint__c='usage/sync', StatusCode__c=202, Response__c='queued'); } catch(Exception e) {}
        }
        return true;
    }
}
