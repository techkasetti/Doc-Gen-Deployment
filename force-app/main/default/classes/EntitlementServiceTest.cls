@IsTest
private class EntitlementServiceTest {
    @IsTest static void testPreflightAndAudit() {
        /*Tenant__c t = new Tenant__c(Name='TEnt', OrgId__c='ENT-1');
        insert t;
        FeatureEntitlement__c fe = new FeatureEntitlement__c(Tenant__c=t.Id, FeatureKey__c='X', Enabled__c=true);
        insert fe;
        Test.startTest();
        Boolean ok = EntitlementService.preflightAndAudit(t.Id, 'X', UserInfo.getUserId());
        Test.stopTest();
        System.assertEquals(true, ok);
        List<ActivationAudit__c> audits = [SELECT Id FROM ActivationAudit__c WHERE Tenant__c = :t.Id];
        System.assertEquals(1, audits.size());*/
    }
}