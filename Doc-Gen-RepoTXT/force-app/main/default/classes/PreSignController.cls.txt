public with sharing class PreSignController {
    @AuraEnabled public static Map<String,Object> runPreSign(Id documentId) {
        return PreSignValidator.validateReadyForSign(documentId);
    }
}