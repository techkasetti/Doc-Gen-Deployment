public with sharing class BlockchainController {
    @AuraEnabled
    public static Map<String,Object> createAnchor(List<Id> auditIds) {
        Map<String,Object> out = new Map<String,Object>{ 'anchorId' => null, 'status' => 'queued' };
        if (auditIds == null || auditIds.isEmpty()) { out.put('status','error'); out.put('error','missing_audits'); return out; }
        // TODO: call external anchoring service or on-chain writer via Named Credential
        out.put('anchorId', 'anchor-'+String.valueOf(Datetime.now().getTime()));
        out.put('status','created');
        return out;
    }
}