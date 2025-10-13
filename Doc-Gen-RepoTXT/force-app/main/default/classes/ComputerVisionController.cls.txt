public with sharing class ComputerVisionController {
    @AuraEnabled
    public static Map<String,Object> analyzeImage(String contentVersionId) {
        Map<String,Object> out = new Map<String,Object>{ 'contentVersionId' => contentVersionId, 'status' => 'analyzed' };
        if (String.isBlank(contentVersionId)) { out.put('status','error'); out.put('error','missing_cv'); return out; }
        // TODO: call OCR/vision provider via Named Credential
        out.put('labels', new List<String>{'document','id'});
        return out;
    }
}
