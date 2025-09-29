public with sharing class ProvisioningAuditWriter {
    public static Id write(String context, String message, Map<String,Object> meta) {
        if (!Schema.getGlobalDescribe().containsKey('Provisioning_Audit__c')) return null;
        try {
            Provisioning_Audit__c a = new Provisioning_Audit__c(Context__c=context, Message__c=message, Metadata__c=meta==null?null:JSON.serialize(meta), Created_At__c=Datetime.now());
            insert a;
            return a.Id;
        } catch(Exception ex) {
            return null;
        }
    }
}
