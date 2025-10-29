public with sharing class ExportFinalizeController {
    @AuraEnabled public static Boolean finalizeExport(Id fileId) {
        if (fileId == null) return false;
        // stub finalize steps
        return true;
    }
}