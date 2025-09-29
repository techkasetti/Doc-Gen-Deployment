public with sharing class DocumentReasoningEngine {
    @AuraEnabled
    public static Map<String,Object> reasonAcrossDocuments(List<Id> documentIds) {
        Map<String,Object> out = new Map<String,Object>{'ok'=>false,'insights'=>null,'message'=>null};
        try {
            if (documentIds == null || documentIds.isEmpty()) { out.put('message','no docs'); return out; }
            List<Map<String,Object>> insights = new List<Map<String,Object>>();
            for (Id dId : documentIds) {
                Map<String,Object> i = new Map<String,Object>{'docId'=>dId, 'theme'=>'theme-placeholder', 'confidence'=>0.6};
                insights.add(i);
            }
            out.put('ok', true);
            out.put('insights', insights);
            return out;
        } catch(Exception ex) {
            out.put('message', ex.getMessage());
            return out;
        }
    }
}
