public with sharing class ExportWithLockController {
    @AuraEnabled public static Boolean exportWithLock(String lockKey) {
        if (String.isBlank(lockKey)) return false;
        // stub: acquire lock via Custom Metadata or LockManager then export
        return true;
    }
}
