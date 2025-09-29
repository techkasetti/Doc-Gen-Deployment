public with sharing class DocumentLifecycleDeploymentManager {
    public class AssemblyResult { public Boolean ok; public String message; public Id contentVersionId; }
    @AuraEnabled
    public static AssemblyResult assembleDocument(Id templateId, Map<String,Object> mergeData) {
        AssemblyResult r = new AssemblyResult();
        r.ok = false; r.message = null; r.contentVersionId = null;
        try {
            if (templateId == null) {
                r.message = 'missing templateId';
                return r;
            }
            // minimal assembly: create an Assembly_Run__c if exists for traceability
            Id runId = null;
            if (Schema.getGlobalDescribe().containsKey('Assembly_Run__c')) {
                Assembly_Run__c ar = new Assembly_Run__c(Name='run-'+String.valueOf(Math.abs(Crypto.getRandomLong())), Template__c = templateId, Status__c='COMPLETED', CreatedAt__c = Datetime.now());
                insert ar;
                runId = ar.Id;
            }
            // simulate content creation: create ContentVersion if available
            if (Schema.getGlobalDescribe().containsKey('ContentVersion')) {
                ContentVersion cv = new ContentVersion(Title='preview-'+String.valueOf(Date.today()), PathOnClient='preview.html', VersionData=Blob.valueOf('<html><body>Preview</body></html>'));
                insert cv;
                ContentVersion cv2 = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
                r.contentVersionId = cv2.ContentDocumentId;
            }
            r.ok = true;
            r.message = 'assembled';
            // write activation audit if object exists
            if (Schema.getGlobalDescribe().containsKey('ActivationAudit__c')) {
                ActivationAudit__c aa = new ActivationAudit__c(Action__c='ASSEMBLE', Notes__c='Run:'+String.valueOf(runId), EffectiveFrom__c = System.now());
                insert aa;
            }
            return r;
        } catch(Exception ex) {
            r.message = ex.getMessage();
            return r;
        }
    }
}
