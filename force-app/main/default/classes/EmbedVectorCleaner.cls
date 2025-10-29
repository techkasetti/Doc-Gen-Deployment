public with sharing class EmbedVectorCleaner {
    public static Integer pruneOldEmbeddings(Integer olderThanDays) {
        if (olderThanDays == null) olderThanDays = 365;
        // stub: in production delete from Document_Embedding__c; here return 0
        return 0;
    }
}