public with sharing class DocumentHelper {

    public static String extractTextContent(String documentId) {
        ContentVersion cv = [
            SELECT VersionData 
            FROM ContentVersion 
            WHERE ContentDocumentId = :documentId 
            ORDER BY CreatedDate DESC 
            LIMIT 1
        ];

        Blob fileData = cv.VersionData;
        return fileData.toString();
    }
}
