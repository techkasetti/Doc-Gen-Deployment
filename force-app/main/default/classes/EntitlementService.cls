public with sharing class EntitlementService {
    // Fast-path: check whether tenant+feature is enabled
    public static Boolean isFeatureEnabled(Id tenantId, String featureKey) {
        if (tenantId == null || String.isBlank(featureKey)) return false;
        FeatureEntitlement__c fe = [
            SELECT Enabled__c FROM FeatureEntitlement__c
            WHERE Tenant__c = :tenantId AND FeatureKey__c = :featureKey
            LIMIT 1
        ];
        return fe != null && fe.Enabled__c;
    }

    // API for preflight checks that also writes ActivationAudit__c when toggles change
    public static Boolean preflightAndAudit(Id tenantId, String featureKey, Id actorId) {
        Boolean enabled = isFeatureEnabled(tenantId, featureKey);
        ActivationAudit__c a = new ActivationAudit__c(Tenant__c = tenantId, FeatureKey__c = featureKey, ActivatedBy__c = String.valueOf(actorId));
        insert a;
        return enabled;
    }
}