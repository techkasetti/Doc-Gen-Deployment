public with sharing class AccessRevocationService {
    public static Boolean revokeAccessForUser(Id userId) {
        if (userId == null) return false;
        // stub: in production delete Document_Access__c rows and emit audit
        return true;
    }
}
