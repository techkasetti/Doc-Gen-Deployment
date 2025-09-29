public with sharing class ClauseApprovalController {
    @AuraEnabled public static Boolean submitForApproval(Id clauseId, Id approverId) {
        try {
            if (clauseId == null || approverId == null) return false;
            if (!Schema.getGlobalDescribe().containsKey('Clause_Approval__c')) return false;
            Clause_Approval__c ap = new Clause_Approval__c(Clause__c = clauseId, Approver__c = approverId, Status__c='PENDING', RequestedAt__c = Datetime.now());
            insert ap;
            return true;
        } catch(Exception ex) { return false; }
    }
}
