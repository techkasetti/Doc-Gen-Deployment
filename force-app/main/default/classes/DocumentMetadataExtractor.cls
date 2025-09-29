public with sharing class DocumentMetadataExtractor {
    public static Map<String,String> extractMetadata(Id documentId) {
        Map<String,String> out = new Map<String,String>();
        if (documentId == null) return out;
        out.put('title', 'doc-'+String.valueOf(documentId));
        out.put('length', '0');
        return out;
    }
}