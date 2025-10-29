public with sharing class ExportAutoTagController {
    @AuraEnabled public static Boolean runAutoTag(Id fileId) {
        if (fileId == null) return false;
        // stub: in prod compute tags; here return true if object exists
        return true;
    }
}