public with sharing class CompliancePacketGenerator {
    public static Id generatePacket(Id documentId) {
        try {
            if (documentId == null) return null;
            if (!Schema.getGlobalDescribe().containsKey('Compliance_Packet__c')) return null;
            Compliance_Packet__c p = new Compliance_Packet__c(Document__c = documentId, GeneratedAt__c = Datetime.now());
            insert p;
            return p.Id;
        } catch(Exception ex) {
            return null;
        }
    }
}