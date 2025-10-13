@IsTest
private class DocumentLifecycleDeploymentManagerTest {
    @IsTest static void testInitializeSystemDefaults() {
        Test.startTest();
        DocumentLifecycleDeploymentManager.initializeSystemDefaults();
        Test.stopTest();
        Integer tenantCount = [SELECT count() FROM Tenant__c];
        System.assert(tenantCount >= 1);
        Integer feCount = [SELECT count() FROM FeatureEntitlement__c];
        System.assert(feCount >= 1);
    }
}
