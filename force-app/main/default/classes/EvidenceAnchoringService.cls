public with sharing class EvidenceAnchoringService {
    public static Boolean anchorEvidence(Id evidenceBundleId, String anchorProvider) {
        if (evidenceBundleId == null || String.isBlank(anchorProvider)) return false;
        // Stub: write Integration_Call__c for anchoring event
        if (Schema.getGlobalDescribe().containsKey('Integration_Call__c')) {
            try { insert new Integration_Call__c(Endpoint__c='anchor/'+anchorProvider, StatusCode__c=200, Response__c='anchored'); } catch(Exception e) {}
        }
        return true;
    }
}