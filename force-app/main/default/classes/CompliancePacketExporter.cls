public with sharing class CompliancePacketExporter {
    public static String getExportUrl(Id packetId) {
        try {
            if (packetId == null) return null;
            if (!Schema.getGlobalDescribe().containsKey('Compliance_Packet__c')) return null;
            return '/packets/' + String.valueOf(packetId) + '/download';
        } catch(Exception ex) { return null; }
    }
}