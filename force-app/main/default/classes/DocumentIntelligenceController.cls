public with sharing class DocumentIntelligenceController {
    // Analyze a document, persist a lightweight intelligence record if object exists.
    @AuraEnabled
    public static Map<String,Object> analyzeDocument(Id documentId) {
        Map<String,Object> out = new Map<String,Object>{'ok'=>false,'message'=>null,'result'=>null};
        try {
            if (documentId == null) {
                out.put('message','missing documentId');
                return out;
            }
            // defensive: ensure target object exists
            if (!Schema.getGlobalDescribe().containsKey('Document__c')) {
                out.put('message','Document__c not present in org');
                return out;
            }
            Document__c d = [SELECT Id, Name FROM Document__c WHERE Id = :documentId LIMIT 1];
            // Lightweight analysis (placeholder for LLM/embedding call)
            Map<String,Object> result = new Map<String,Object>();
            result.put('documentId', d.Id);
            result.put('summary', 'Auto-generated summary placeholder for doc '+String.valueOf(d.Id));
            result.put('score', 0.75);
            out.put('ok', true);
            out.put('result', result);
            // persist provenance record if object exists
            if (Schema.getGlobalDescribe().containsKey('Document_Provenance__c')) {
                try {
                    Document_Provenance__c p = new Document_Provenance__c(
                        Document__c = d.Id,
                        Metadata__c = JSON.serialize(result),
                        RecordedAt__c = Datetime.now()
                    );
                    insert p;
                } catch(Exception e) {
                    // best-effort; do not fail main flow
                    Error_Log__c el = Schema.getGlobalDescribe().containsKey('Error_Log__c') ? new Error_Log__c(Message__c='ProvWriteErr: '+e.getMessage()) : null;
                    if (el != null) {
                        try { insert el; } catch(Exception ignore){}
                    }
                }
            }
            return out;
        } catch(Exception ex) {
            out.put('message','exception: '+ex.getMessage());
            return out;
        }
    }
}