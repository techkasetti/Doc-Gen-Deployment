public with sharing class DocumentAssemblyService {
    public class AssemblyResult {
        @AuraEnabled public Boolean ok;
        @AuraEnabled public String message;
        @AuraEnabled public Id contentVersionId;
        public AssemblyResult() {
            ok = false;
            message = null;
            contentVersionId = null;
        }
    }

    /**
     * Assemble a document from a Document_Template__c record and merge data.
     * - Replaces placeholders of the form {{KEY}} where KEY is a mergeData key.
     * - Persists the assembled HTML as a ContentVersion (PathOnClient: .html).
     * - Creates a simple generation audit record if Document_Generation_Audit__c exists.
     */
    @AuraEnabled
    public static AssemblyResult assembleDocument(Id templateId, Map<String, Object> mergeData) {
        AssemblyResult r = new AssemblyResult();
        try {
            if (templateId == null) {
                r.message = 'missing templateId';
                return r;
            }

            String templateContent = '';
            String templateName = 'generated-document';

            // Load template if custom object exists
            if (Schema.getGlobalDescribe().containsKey('Document_Template__c')) {
                try {
                    DocumentTemplate__c t = [
                        SELECT Id, Template_Content__c, Template_Name__c
                        FROM DocumentTemplate__c
                        WHERE Id = :templateId
                        LIMIT 1
                    ];
                    templateContent = t.Template_Content__c != null ? t.Template_Content__c : '';
                    templateName = t.Template_Name__c != null ? t.Template_Name__c : templateName;
                } catch (Exception ex) {
                    // Template not found or query failed
                    r.message = 'template not found or inaccessible: ' + ex.getMessage();
                    return r;
                }
            } else {
                r.message = 'Document_Template__c type not available in this org';
                return r;
            }

            // Simple placeholder merge: replace {{KEY}} with value strings
            String assembled = templateContent;
            if (mergeData != null && !mergeData.isEmpty()) {
                for (String k : mergeData.keySet()) {
                    Object v = mergeData.get(k);
                    String sval = v == null ? '' : String.valueOf(v);
                    assembled = assembled.replaceAll('\\Q{{' + k + '}}\\E', Matcher.quoteReplacement(sval));
                }
            }

            // Ensure there is some output
            if (String.isBlank(assembled)) {
                assembled = '<html><body><!-- empty document --></body></html>';
            }

            // Persist as ContentVersion if available
            if (!Schema.getGlobalDescribe().containsKey('ContentVersion')) {
                r.message = 'ContentVersion not available in target org';
                return r;
            }

            ContentVersion cv = new ContentVersion();
            cv.Title = templateName;
            cv.PathOnClient = templateName + '.html';
            cv.VersionData = Blob.valueOf(assembled);
            // Optional metadata fields that are safe to set if present in org (guarded by schema)
            try {
                insert cv;
                r.contentVersionId = cv.Id;
            } catch (Exception ex) {
                r.message = 'Failed to insert ContentVersion: ' + ex.getMessage();
                return r;
            }

            // Create a generation audit record if object exists. Use dynamic SObject to avoid compile-time field issues.
            if (Schema.getGlobalDescribe().containsKey('Document_Generation_Audit__c')) {
                try {
                    SObject auditRec = Schema.getGlobalDescribe().get('Document_Generation_Audit__c').newSObject();
                    // Common audit fields we try to populate if they exist; use dynamic put so compilation won't fail.
                    auditRec.put('Template_Used__c', templateId);
                    auditRec.put('Generation_Parameters__c', JSON.serialize(mergeData));
                    auditRec.put('Status__c', 'COMPLETED');
                    auditRec.put('ContentVersion_Id__c', r.contentVersionId);
                    auditRec.put('Generation_Timestamp__c', Datetime.now());
                    insert auditRec;
                } catch (Exception ex) {
                    // Best-effort: do not fail assembly if audit insertion fails
                    System.debug('DocumentAssemblyService: audit insert failed: ' + ex.getMessage());
                }
            }

            r.ok = true;
            r.message = 'assembled';
            return r;
        } catch (Exception e) {
            r.ok = false;
            r.message = 'assembly failed: ' + e.getMessage();
            return r;
        }
    }
}