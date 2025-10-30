public with sharing class DocumentGenerationController {
    /**
     * Returns a preview for a document template and data (similar to preview method).
     */
    @AuraEnabled
    public static Map<String, Object> getPreview(Id templateId, Map<String, Object> data) {
        Map<String, Object> out = new Map<String, Object>{'ok'=>false,'message'=>null,'previewUrl'=>null};
        try {
            DocumentLifecycleDeploymentManager.AssemblyResult r = DocumentLifecycleDeploymentManager.assembleDocument(templateId, data);
            if (r == null || !r.ok) {
                out.put('message', 'assembly failed');
                return out;
            }
            out.put('ok', true);
            out.put('previewUrl', '/sfc/servlet.shepherd/version/download/' + String.valueOf(r.contentVersionId));
            return out;
        } catch (Exception ex) {
            out.put('message', ex.getMessage());
            return out;
        }
    }
    /**
     * Creates a signature request for a generated document and returns the request Id.
     */
    @AuraEnabled
    public static Map<String, Object> generateAndRequestSignature(Id configId, String signerEmail, String signerName) {
        Map<String, Object> out = new Map<String, Object>{'ok'=>false, 'message'=>null, 'signatureRequestId'=>null};
        try {
            // In production, this would trigger an e-signature workflow and persist a record
            if (!Schema.getGlobalDescribe().containsKey('Signature_Request__c')) {
                out.put('message', 'Signature_Request__c object not available');
                return out;
            }
            Signature_Request__c req = new Signature_Request__c();
            req.Document_Config_Id__c = configId;
            req.Signer_Email__c = signerEmail;
            req.Signer_Name__c = signerName;
            req.Status__c = 'Requested';
            insert req;
            out.put('ok', true);
            out.put('signatureRequestId', req.Id);
            return out;
        } catch (Exception ex) {
            out.put('message', 'Failed to create signature request: ' + ex.getMessage());
            return out;
        }
    }
    /**
     * Creates a Document__c record for a document generation request.
     * Returns the new document Id.
     */
    @AuraEnabled
    public static Id createDocumentRequest(String documentType, String region, String role, String templateId, String additionalClauses) {
        try {
            if (!Schema.getGlobalDescribe().containsKey('Document__c')) {
                throw new AuraHandledException('Document__c object not available');
            }
            Document__c doc = new Document__c();
            doc.Name = 'Generated-' + String.valueOf(DateTime.now());
            if (documentType != null) doc.Document_Type__c = documentType;
            if (region != null) doc.Region__c = region;
            if (role != null) doc.Role__c = role;
            if (templateId != null) doc.Template_Id__c = templateId;
            if (additionalClauses != null) doc.Additional_Clauses__c = additionalClauses;
            insert doc;
            return doc.Id;
        } catch (Exception ex) {
            throw new AuraHandledException('Failed to create document request: ' + ex.getMessage());
        }
    }
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