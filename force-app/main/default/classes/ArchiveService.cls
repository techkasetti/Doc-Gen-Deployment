public class ArchiveService {
    public static void archiveDocument(String documentId, String archiveLocation, Boolean encryptionRequired) {
        // Implementation for document archival
        DocumentArchive__c archive = new DocumentArchive__c(
            Original_Document_Id__c = documentId,
            Archive_Location__c = archiveLocation,
            Encryption_Applied__c = encryptionRequired,
            Archive_Timestamp__c = DateTime.now(),
            Archive_Status__c = 'COMPLETED'
        );
        insert archive;
    }
}