public with sharing class DocumentGenerationController {
    @AuraEnabled
    public static Map<String,Object> preview(Id templateId, Map<String,Object> data) {
        Map<String,Object> out = new Map<String,Object>{'ok'=>false,'message'=>null,'previewUrl'=>null};
        try {
            DocumentLifecycleDeploymentManager.AssemblyResult r = DocumentLifecycleDeploymentManager.assembleDocument(templateId, data);
            if (r == null || !r.ok) { out.put('message','assembly failed'); return out; }
            out.put('ok', true);
            out.put('previewUrl', '/sfc/servlet.shepherd/version/download/'+String.valueOf(r.contentVersionId));
            return out;
        } catch(Exception ex) {
            out.put('message', ex.getMessage());
            return out;
        }
    }
    @AuraEnabled
    public static Map<String,Object> generate(Id templateId, Map<String,Object> data) {
        Map<String,Object> out = new Map<String,Object>{'ok'=>false,'message'=>null,'documentId'=>null};
        try {
            Map<String,Object> p = preview(templateId, data);
            if (!((Boolean)p.get('ok'))) { out.put('message','preview failed'); return out; }
            // in production this would create a persisted document record and trigger sign workflows
            if (Schema.getGlobalDescribe().containsKey('Document__c')) {
                Document__c d = new Document__c(Name='Generated-'+String.valueOf(DateTime.now()));
                insert d;
                out.put('documentId', d.Id);
            }
            out.put('ok', true);
            return out;
        } catch(Exception ex) {
            out.put('message', ex.getMessage());
            return out;
        }
    }
}
