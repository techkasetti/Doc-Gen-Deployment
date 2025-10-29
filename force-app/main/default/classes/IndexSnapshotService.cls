public with sharing class IndexSnapshotService {
    public static Boolean createSnapshot(String indexId, String destination) {
        if (String.isBlank(indexId) || String.isBlank(destination)) return false;
        // stub: in production call FAISS snapshot loader
        return true;
    }
}