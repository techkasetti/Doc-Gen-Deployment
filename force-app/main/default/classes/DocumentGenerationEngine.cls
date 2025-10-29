public with sharing class DocumentGenerationEngine {
    /**
     * Generate a document from a template, merge map, and additional context data.
     * Context data is merged into the template along with mergeData.
     */
    @AuraEnabled(cacheable=false)
    public static GenerationResult generateContextAwareDocument(GenerationRequest req, Map<String, Object> contextData) {
        GenerationResult out = new GenerationResult();
        try {
            if (req == null || String.isBlank(req.templateId)) {
                out.message = 'missing templateId';
                return out;
            }

            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            String templateType = null;
            if (gd.containsKey('Document_Template__c')) templateType = 'Document_Template__c';
            else if (gd.containsKey('DocumentTemplate__c')) templateType = 'DocumentTemplate__c';
            else {
                out.message = 'Template object not found in org';
                return out;
            }

            // Build SELECT fields defensively
            List<String> sel = new List<String>{ 'Id', 'Template_Content__c' };
            Schema.DescribeSObjectResult descr = gd.get(templateType).getDescribe();
            Map<String, Schema.SObjectField> fieldsMap = descr.fields.getMap();
            if (fieldsMap.containsKey('Template_Name__c')) sel.add('Template_Name__c');
            else if (fieldsMap.containsKey('Name')) sel.add('Name');
            if (fieldsMap.containsKey('AI_Instructions__c')) sel.add('AI_Instructions__c');

            String q = 'SELECT ' + String.join(sel, ', ') + ' FROM ' + templateType + ' WHERE Id = :req.templateId LIMIT 1';
            SObject tmpl = Database.query(q);

            String templateContent = (String)tmpl.get('Template_Content__c');
            if (templateContent == null) templateContent = '';

            // Merge contextData into template
            if (contextData != null && !contextData.isEmpty()) {
                for (String k : contextData.keySet()) {
                    Object v = contextData.get(k);
                    String sval = v == null ? '' : String.valueOf(v);
                    templateContent = templateContent.replace('{{' + k + '}}', sval);
                }
            }

            // Merge mergeData into template
            if (req.mergeData != null && !req.mergeData.isEmpty()) {
                for (String k : req.mergeData.keySet()) {
                    Object v = req.mergeData.get(k);
                    String sval = v == null ? '' : String.valueOf(v);
                    templateContent = templateContent.replace('{{' + k + '}}', sval);
                }
            }

            // Post-process & ensure HTML wrapper
            String generated = applyPostProcessing(templateContent);

            // Persist to ContentVersion (guard for orgs without ContentVersion)
            if (!Schema.getGlobalDescribe().containsKey('ContentVersion')) {
                out.message = 'ContentVersion object not available';
                return out;
            }

            String title = 'generated-document';
            if (fieldsMap.containsKey('Template_Name__c') && tmpl.get('Template_Name__c') != null) {
                title = String.valueOf(tmpl.get('Template_Name__c'));
            } else if (fieldsMap.containsKey('Name') && tmpl.get('Name') != null) {
                title = String.valueOf(tmpl.get('Name'));
            }

            ContentVersion cv = new ContentVersion();
            cv.Title = title;
            cv.PathOnClient = title + (req.outputFormat != null && req.outputFormat.toLowerCase() == 'pdf' ? '.pdf' : '.html');
            cv.VersionData = Blob.valueOf(generated);
            insert cv;

            out.success = true;
            out.message = 'generated';
            out.contentVersionId = cv.Id;
            out.contentDocumentId = cv.ContentDocumentId;
            out.metadata.put('length', generated.length());

            // Best-effort: dynamic audit insertion (avoids compile-time coupling)
            if (Schema.getGlobalDescribe().containsKey('Document_Generation_Audit__c')) {
                try {
                    SObject auditRec = Schema.getGlobalDescribe().get('Document_Generation_Audit__c').newSObject();
                    auditRec.put('Template_Used__c', req.templateId);
                    auditRec.put('Status__c', 'COMPLETED');
                    auditRec.put('ContentDocumentId__c', cv.ContentDocumentId);
                    auditRec.put('Generation_Parameters__c', JSON.serialize(req.mergeData));
                    auditRec.put('Context_Data__c', JSON.serialize(contextData));
                    auditRec.put('Generation_Timestamp__c', Datetime.now());
                    insert auditRec;
                    out.metadata.put('auditId', String.valueOf(auditRec.get('Id')));
                } catch (Exception ex) {
                    // non-fatal
                    System.debug('DocumentGenerationEngine.auditInsert failed: ' + ex.getMessage());
                }
            }

            return out;

        } catch (Exception e) {
            out.success = false;
            out.message = 'generation error: ' + e.getMessage();
            return out;
        }
    }

    // Input DTO
    public class GenerationRequest {
        @AuraEnabled public String templateId;
        @AuraEnabled public Map<String, Object> mergeData;
        @AuraEnabled public String outputFormat;
        @AuraEnabled public List<String> generationOptions;
        public GenerationRequest() {
            mergeData = new Map<String,Object>();
            outputFormat = 'html';
            generationOptions = new List<String>();
        }
    }

    // Output DTO
    public class GenerationResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public Id contentDocumentId;
        @AuraEnabled public Id contentVersionId;
        @AuraEnabled public Map<String, Object> metadata;
        public GenerationResult() {
            success = false;
            message = null;
            contentDocumentId = null;
            contentVersionId = null;
            metadata = new Map<String,Object>();
        }
    }

    /**
     * Generate a document from a template + merge map.
     * Defensive: checks for template object presence, ContentVersion presence, and uses dynamic audit insertion.
     */
    @AuraEnabled(cacheable=false)
    public static GenerationResult generateDocument(GenerationRequest req) {
        GenerationResult out = new GenerationResult();
        try {
            if (req == null || String.isBlank(req.templateId)) {
                out.message = 'missing templateId';
                return out;
            }

            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            String templateType = null;
            if (gd.containsKey('Document_Template__c')) templateType = 'Document_Template__c';
            else if (gd.containsKey('DocumentTemplate__c')) templateType = 'DocumentTemplate__c';
            else {
                out.message = 'Template object not found in org';
                return out;
            }

            // Build SELECT fields defensively
            List<String> sel = new List<String>{ 'Id', 'Template_Content__c' };
            Schema.DescribeSObjectResult descr = gd.get(templateType).getDescribe();
            Map<String, Schema.SObjectField> fieldsMap = descr.fields.getMap();
            if (fieldsMap.containsKey('Template_Name__c')) sel.add('Template_Name__c');
            else if (fieldsMap.containsKey('Name')) sel.add('Name');
            if (fieldsMap.containsKey('AI_Instructions__c')) sel.add('AI_Instructions__c');

            String q = 'SELECT ' + String.join(sel, ', ') + ' FROM ' + templateType + ' WHERE Id = :req.templateId LIMIT 1';
            SObject tmpl = Database.query(q);

            String templateContent = (String)tmpl.get('Template_Content__c');
            if (templateContent == null) templateContent = '';

            // Simple placeholder merge: {{KEY}} -> value
            if (req.mergeData != null && !req.mergeData.isEmpty()) {
                for (String k : req.mergeData.keySet()) {
                    Object v = req.mergeData.get(k);
                    String sval = v == null ? '' : String.valueOf(v);
                    templateContent = templateContent.replace('{{' + k + '}}', sval);
                }
            }

            // If you want to plug an AI model, add a call here; but avoid direct static references
            // to external helper classes at compile time (we intentionally do not call any AI helpers here).

            // Post-process & ensure HTML wrapper
            String generated = applyPostProcessing(templateContent);

            // Persist to ContentVersion (guard for orgs without ContentVersion)
            if (!Schema.getGlobalDescribe().containsKey('ContentVersion')) {
                out.message = 'ContentVersion object not available';
                return out;
            }

            String title = 'generated-document';
            if (fieldsMap.containsKey('Template_Name__c') && tmpl.get('Template_Name__c') != null) {
                title = String.valueOf(tmpl.get('Template_Name__c'));
            } else if (fieldsMap.containsKey('Name') && tmpl.get('Name') != null) {
                title = String.valueOf(tmpl.get('Name'));
            }

            ContentVersion cv = new ContentVersion();
            cv.Title = title;
            cv.PathOnClient = title + (req.outputFormat != null && req.outputFormat.toLowerCase() == 'pdf' ? '.pdf' : '.html');
            cv.VersionData = Blob.valueOf(generated);
            insert cv;

            out.success = true;
            out.message = 'generated';
            out.contentVersionId = cv.Id;
            out.contentDocumentId = cv.ContentDocumentId;
            out.metadata.put('length', generated.length());

            // Best-effort: dynamic audit insertion (avoids compile-time coupling)
            if (Schema.getGlobalDescribe().containsKey('Document_Generation_Audit__c')) {
                try {
                    SObject auditRec = Schema.getGlobalDescribe().get('Document_Generation_Audit__c').newSObject();
                    auditRec.put('Template_Used__c', req.templateId);
                    auditRec.put('Status__c', 'COMPLETED');
                    auditRec.put('ContentDocumentId__c', cv.ContentDocumentId);
                    auditRec.put('Generation_Parameters__c', JSON.serialize(req.mergeData));
                    auditRec.put('Generation_Timestamp__c', Datetime.now());
                    insert auditRec;
                    out.metadata.put('auditId', String.valueOf(auditRec.get('Id')));
                } catch (Exception ex) {
                    // non-fatal
                    System.debug('DocumentGenerationEngine.auditInsert failed: ' + ex.getMessage());
                }
            }

            return out;

        } catch (Exception e) {
            out.success = false;
            out.message = 'generation error: ' + e.getMessage();
            return out;
        }
    }

    // Minimal post-processing to ensure produced HTML is wrapped  
    private static String applyPostProcessing(String content) {
        if (String.isBlank(content)) content = '<html><body></body></html>';
        if (!content.toLowerCase().contains('<html')) {
            content = '<html><body>' + content + '</body></html>';
        }
        return content;
    }

}