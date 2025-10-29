public with sharing class DocumentUnlockService {
    public static Boolean unlockDocument(Id documentId, Id userId) {
        if (documentId == null || userId == null) return false;
        // stub: remove lock record
        return true;
    }
}