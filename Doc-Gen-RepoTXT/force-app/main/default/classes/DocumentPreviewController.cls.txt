public with sharing class DocumentPreviewController {
    @AuraEnabled public static Map<String,Object> getPreview(Id documentId) {
        Map<String,Object> out = new Map<String,Object>{'ok'=>false};
        if (documentId == null) return out;
        // attempt to locate ContentVersion preview
        out.put('ok', true);
        out.put('previewUrl', '/sfc/servlet.shepherd/version/download/' + String.valueOf(documentId));
        return out;
    }
}