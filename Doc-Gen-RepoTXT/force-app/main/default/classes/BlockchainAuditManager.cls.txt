public class BlockchainAuditManager {
    public static void createImmutableAuditRecord(String recordId, String action, String details) {
        // Implementation for blockchain audit trail
        BlockchainAudit__c audit = new BlockchainAudit__c(
            Record_Id__c = recordId,
            Action_Type__c = action,
            Action_Details__c = details,
            Block_Hash__c = generateBlockHash(recordId, action, details),
            Timestamp__c = DateTime.now(),
            Previous_Block_Hash__c = getLastBlockHash()
        );
        insert audit;
    }
    
    private static String generateBlockHash(String recordId, String action, String details) {
        String dataToHash = recordId + action + details + String.valueOf(DateTime.now().getTime());
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA256', Blob.valueOf(dataToHash)));
    }
    
    private static String getLastBlockHash() {
        try {
            BlockchainAudit__c lastBlock = [
                SELECT Block_Hash__c 
                FROM BlockchainAudit__c 
                ORDER BY CreatedDate DESC 
                LIMIT 1
            ];
            return lastBlock.Block_Hash__c;
        } catch (QueryException e) {
            return 'GENESIS_BLOCK';
        }
    }
}
