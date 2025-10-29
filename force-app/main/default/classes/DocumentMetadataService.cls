public with sharing class DocumentMetadataService {
    @AuraEnabled public static Map<String,Object> getMetadata(Id documentId) {
        Map<String,Object> out = new Map<String,Object>{'ok'=>false,'meta'=>new Map<String,Object>()};
        if (documentId == null) return out;
        try {
            if (!Schema.getGlobalDescribe().containsKey('Document__c')) { out.put('ok', true); return out; }
            Document__c d = [SELECT Id, Name, CreatedDate FROM Document__c WHERE Id = :documentId LIMIT 1];
            out.put('ok', true);
            Map<String, Object> meta = (Map<String, Object>)out.get('meta');
            meta.put('name', d.Name);
            meta.put('createdAt', String.valueOf(d.CreatedDate));
            out.put('meta', meta);
            return out;
        } catch(Exception ex) {
            out.put('ok', false);
            out.put('error', ex.getMessage());
            return out;
        }
    }
}