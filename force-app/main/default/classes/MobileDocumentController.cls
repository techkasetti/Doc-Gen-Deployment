public with sharing class MobileDocumentController {
    @AuraEnabled
    public static Map<String,Object> fetchForMobile(Id documentId) {
        if (documentId == null) return new Map<String,Object>{'ok'=>false};
        return new Map<String,Object>{'ok'=>true,'documentId'=>String.valueOf(documentId)};
    }
}