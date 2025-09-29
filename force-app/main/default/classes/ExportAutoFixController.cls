public with sharing class ExportAutoFixController {
    @AuraEnabled public static Boolean applyFix(String connectorKey) {
        if (String.isBlank(connectorKey)) return false;
        // stub: in prod attempt fixes
        return true;
    }
}
