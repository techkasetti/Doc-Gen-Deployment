public with sharing class Web3Controller {
    @AuraEnabled public static Map<String,Object> submitOnChainProof(String payload) {
        Map<String,Object> out = new Map<String,Object>{'ok'=>false};
        if (String.isBlank(payload)) return out;
        try {
            // Placeholder: call middleware to anchor on-chain
            out.put('ok', true);
            out.put('anchorTx', 'tx-123456');
            out.put('submittedAt', String.valueOf(Datetime.now()));
            return out;
        } catch (Exception ex) {
            out.put('error', ex.getMessage());
            return out;
        }
    }
}
